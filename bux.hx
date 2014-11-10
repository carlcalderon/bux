import Sys;
import sys.io.Process;
import haxe.io.Input;
import haxe.io.Output;

class Bux
{

  static public function main() {
    var bux = new Bux();
    bux.interpret(Sys.args());
    bux.begin();
  }

  private static var VERSION :String = "0.0.1";
  private static var REGEX_COMMAND_LINE_ARGUMENT     :EReg = ~/-(\w)|--(\w+)/;
  private static var REGEX_REGULAR_EXPRESSION_INPUT  :EReg = ~/\/(.+?)\/(\w+?)?/;
  private static var REGEX_COMMAND_REPLACE           :EReg = ~/\{(\d)\}/g;

  private var FLAG_DRY_RUN  :Bool = false;

  private var stdin  :Input;
  private var stdout :Output;

  private var userRegEx     :EReg;
  private var inputBuffer   :String;
  private var commandString :String;


  public function new(){
    stdout = Sys.stdout();
    stdin  = Sys.stdin();
  }

  public function interpret(args:Array<String>):Void {
    for (arg in args) {
      if (REGEX_COMMAND_LINE_ARGUMENT.match(arg)) {
        var flag:String = REGEX_COMMAND_LINE_ARGUMENT.matched(1);
        var long:String = REGEX_COMMAND_LINE_ARGUMENT.matched(2);

        var spec_arg:String = null;
        if (flag != null) {
          spec_arg = flag;
        } else {
          spec_arg = long;
        }
        switch (spec_arg) {
          case "v" | "version":
            printVersion();
            Sys.exit(0);
          case "h" | "help":
            printHelp();
            Sys.exit(0);
          case "d" | "dry-run":
            FLAG_DRY_RUN = true;
        }
      } else if (REGEX_REGULAR_EXPRESSION_INPUT.match(arg)) {
        var pattern:String = REGEX_REGULAR_EXPRESSION_INPUT.matched(1);
        var options:String = "g";
        try {
          options = REGEX_REGULAR_EXPRESSION_INPUT.matched(2);
        } catch (e:String) { }
        if (options == null) {
          options = "g";
        }
        userRegEx = new EReg(pattern, options);
      } else {
        commandString = REGEX_COMMAND_REPLACE.replace(arg, "$$$1");
      }
    }
  }

  public function begin():Void {
    inputBuffer = stdin.readAll().toString();

    if (userRegEx == null) {
      Sys.exit(1);
    }

    var output:String = commandString;
    var indexRegex:EReg = ~/\$(\d)/;
    userRegEx.match(inputBuffer);

    while(indexRegex.match(output)) {
      var groupIndex:Int = Std.parseInt(indexRegex.matched(1));
      var replacement:String = "";
      try {
        replacement = userRegEx.matched(groupIndex);
      } catch (e:String) { }
      if (replacement == null) {
        replacement = "";
      }
      output = indexRegex.replace(output, replacement);
    }

    if (FLAG_DRY_RUN) {
      stdout.writeString(output);
      stdout.flush();
    }
  }

  private function printVersion():Void {
    stdout.writeString(VERSION);
    stdout.flush();
  }

  private function printHelp():Void {
    var msg:String = [
      "bux v" + VERSION,
      "",
      "Usage: bux <Regular Expression> [command]",
      "",
      "-v, --version\tPrint version",
      "-h, --help\tPrint help",
      "-d, --dry-run\tOnly output command build-up result",
    ].join("\n");
    stdout.writeString(msg);
    stdout.flush();
  }
}