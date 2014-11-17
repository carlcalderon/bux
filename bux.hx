import Sys;
import sys.io.Process;
import haxe.io.Input;
import haxe.io.Output;

/**
 * bux application / instance
 */
class Bux
{

  private static var VERSION :String = "0.0.2";

  /**
   * Application entry
   */
  static public function main() {
    var bux = new Bux();
    bux.interpret(Sys.args());
    bux.begin();
  }

  private static var REGEX_COMMAND_LINE_ARGUMENT    :EReg = ~/^-(\w+)|^--(\w+)/;
  private static var REGEX_REGULAR_EXPRESSION_INPUT :EReg = ~/\/(.+?)\/(\w+?)?/;
  private static var REGEX_COMMAND_REPLACE          :EReg = ~/(?<!\\)\{(\d)(?<!\\)\}/g;

  /**
   * Attached to the `--dry-run` flag. If `true` the command specified will not
   * be executed and the argument / command merge will only be traced. This
   * allows the user to validate the command construction prior to live-run.
   */
  private var FLAG_DRY_RUN    :Bool = false;

  /**
   * Attached to the `--lines` flag. If `true`, bux will merge and execute for
   * each line in STDIN rather than merge with complete STDIN buffer. This is
   * handy if you for instance want to keep a list of different arguments in a
   * separate file and execute a cli command for each item in the list.
   *
   * Example:
   *
   * - capitals.txt
   * Sweden, Stockholm
   * Spain, Madrid
   * France, Paris
   *
   * - CL
   * $ cat capitals.txt | bux -ld "/(\w+),\s?([\w\s]+)/i" "{2} is the capital of {1}"
   *
   * - output
   * Stockholm is the capital of Sweden
   * Madrid is the capital of Spain
   * Paris is the capital of France
   */
  private var FLAG_LINE_INPUT :Bool = false;

  /**
   * Forked from bux STDIN
   */
  private var stdin :Input;

  /**
   * Forked to bux STDOUT
   */
  private var stdout :Output;

  /**
   * User inserted regular expression (required). Will be compared to
   * STDIN and injected in the user command.
   */
  private var userRegEx :EReg;

  /**
   * User defined command exec (required). This is the piece which will be
   * injected with matches and groups from the user regular expression.
   */
  private var commandString :String;

  /**
   * @constructor
   * bux instance
   */
  public function new(){
    stdout = Sys.stdout();
    stdin  = Sys.stdin();
  }

  /**
   * Reads an Array of Strings and assigns the proper flags and arguments to
   * the bux process.
   * @param  args :Array<String> List of arguments (typically ARGV)
   */
  public function interpret(args :Array<String>):Void {
    for (arg in args) {
      if (REGEX_COMMAND_LINE_ARGUMENT.match(arg)) {
        var flag :String = REGEX_COMMAND_LINE_ARGUMENT.matched(1);
        var long :String = REGEX_COMMAND_LINE_ARGUMENT.matched(2);
        if (flag != null) {
          if (flag.length > 1) {
            for (subFlag in flag.split("")) {
              registerFlag(subFlag);
            }
          } else {
            registerFlag(flag);
          }
        } else {
          registerFlag(long);
        }
      } else if (REGEX_REGULAR_EXPRESSION_INPUT.match(arg)) {
        var pattern :String = REGEX_REGULAR_EXPRESSION_INPUT.matched(1);
        var options :String = "g";
        try {
          options = REGEX_REGULAR_EXPRESSION_INPUT.matched(2);
        } catch (e :String) { }
        if (options == null) {
          options = "g";
        }
        userRegEx = new EReg(pattern, options);
      } else {
        commandString = REGEX_COMMAND_REPLACE.replace(arg, "$$$1");
      }
    }
    if (userRegEx == null || commandString == null) {
      printHelp(1);
    }
  }

  /**
   * Assigns the proper process flag based on input.
   * @param  flag :String       A single flag (leading dash `-` omitted)
   */
  private function registerFlag(flag :String):Void {
    switch (flag) {
      case "v" | "version": printVersion();
      case "h" | "help":    printHelp();
      case "d" | "dry-run": FLAG_DRY_RUN    = true;
      case "l" | "lines":   FLAG_LINE_INPUT = true;
    }
  }

  /**
   * Starts the regular expression and command merge and execution.
   */
  public function begin():Void {
    var regex   :EReg   = userRegEx;
    var command :String = commandString;
    var input   :String = stdin.readAll().toString();

    if (FLAG_LINE_INPUT == false) {
      exec(merge(input, regex, command));
    } else {
      var lines :Array<String> = input.split("\n");
      for (line in lines) {
        exec(merge(line, regex, command));
      }
    }
  }

  /**
   * Merges multiple inputs and returns the combined result.
   * @param  input   :String       Typically STDIN / line
   * @param  regex   :EReg         Merge rule (regular expression)
   * @param  command :String       CL command to merge into
   * @return         :String|null  If no replacement was performed null will be
   *                               returned instead.
   */
  private function merge(input :String, regex :EReg, command :String):String {
    var output     :String = command;
    var foundMatch :Bool   = false;
    var indexRegex :EReg   = ~/\$(\d)/;
    regex.match(input);

    while(indexRegex.match(output)) {
      var groupIndex  :Int    = Std.parseInt(indexRegex.matched(1));
      var replacement :String = "";
      try {
        replacement = regex.matched(groupIndex);
      } catch (e :String) { }
      if (replacement != "") {
        foundMatch = true;
      }
      output = indexRegex.replace(output, replacement);
    }
    if (!foundMatch) {
      return null;
    }
    return output;
  }

  /**
   * Executes a CL program. If `--dry-run` flag is specified, command will be
   * traced to STDOUT instead.
   * @param  command :String       Command to execute
   */
  private function exec(command :String):Void {
    if (command == null) {
      return;
    }
    if (FLAG_DRY_RUN) {
      stdout.writeString(command + "\n");
      stdout.flush();
    } else {
      var arguments :Array<String> = ~/(?<!\\)\s/.split(command);
      var cmd       :String        = arguments.shift();
      var process:Process = new Process(cmd, arguments);
      stdout.writeString(process.stdout.readAll().toString());
      stdout.flush();
    }
  }

  /**
   * Trace version.
   * @param  exitCode :UInt         (optional)
   */
  private function printVersion(exitCode :UInt = 0):Void {
    stdout.writeString(VERSION);
    stdout.flush();
    Sys.exit(exitCode);
  }

  /**
   * Trace help and usage.
   * @param  exitCode :UInt         (optional)
   */
  private function printHelp(exitCode :UInt = 0):Void {
    var information:String = [
      "bux v" + VERSION,
      "",
      "Usage: bux <regular expression> <command>",
      "",
      "-v, --version\tPrint version",
      "-h, --help\tPrint help",
      "-l, --lines\tExecute [command] for each line in STDIN",
      "-d, --dry-run\tOnly output command build-up result",
    ].join("\n");
    stdout.writeString(information);
    stdout.flush();
    Sys.exit(exitCode);
  }
}