import Sys;
import sys.io.Process;
import haxe.io.Input;
import haxe.io.Output;

class Bux
{

  private static var VERSION :String = "0.0.1";

  static public function main() {
    var bux = new Bux();
    bux.interpret(Sys.args());
    bux.begin();
  }

  private static var REGEX_COMMAND_LINE_ARGUMENT    :EReg = ~/^-(\w+)|^--(\w+)/;
  private static var REGEX_REGULAR_EXPRESSION_INPUT :EReg = ~/\/(.+?)\/(\w+?)?/;
  private static var REGEX_COMMAND_REPLACE          :EReg = ~/(?<!\\)\{(\d)(?<!\\)\}/g;

  private var FLAG_DRY_RUN    :Bool = false;
  private var FLAG_LINE_INPUT :Bool = false;

  private var stdin  :Input;
  private var stdout :Output;

  /**
   * User inserted regular expression (required). Will be compared to
   * STDIN and injected in the user command.
   */
  private var userRegEx :EReg;

  /**
   * User defined command exec. This is the piece which will be injected with
   * matches and groups from the user regular expression.
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
    if (userRegEx == null) {
      printHelp(1);
    }
  }

  private function registerFlag(flag :String):Void {
    switch (flag) {
      case "v" | "version": printVersion();
      case "h" | "help":    printHelp();
      case "d" | "dry-run": FLAG_DRY_RUN    = true;
      case "l" | "lines":   FLAG_LINE_INPUT = true;
    }
  }

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

  private function exec(command :String):Void {
    if (command == null) {
      return;
    }
    if (FLAG_DRY_RUN) {
      stdout.writeString(command + "\n");
      stdout.flush();
    } else {
      // exec the command
    }
  }

  private function printVersion(exitCode :UInt = 0):Void {
    stdout.writeString(VERSION);
    stdout.flush();
    Sys.exit(exitCode);
  }

  private function printHelp(exitCode :UInt = 0):Void {
    var information:String = [
      "bux v" + VERSION,
      "",
      "Usage: bux <Regular Expression> [command]",
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