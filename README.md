# bux
*xargs that makes sense*

## Introduction
`bux` is a small terminal program that can digest text based input and execute
other CL programs based on a regular expression ruleset.

## Compiling
`bus` is built using the `Haxe` compiler and require `hxcpp` to compile. The
`hxcpp` library can be installed using the `haxelib` program like so:

	$ haxelib install hxcpp

To build `bux` you simply execute the following line in the project directory.
This will create a `bux.cpp` folder with the C++ output and a `bin` folder where
you will find the finished `bux` executable binary.

	$ haxe build.hxml

## Usage
`bux` takes 2 arguments; regular expression (rules) and command like so:

	$ bux [flags] <regular expression> <command>

The regular expression and command should be wrapped within quotes to avoid
misinterpretation.

The command may hold replace placeholders in the form of `{#}`. Where the `#`
represents the regular expression group to be used. Currently `bux` allows for
`0` to `9` groups where 0 is the complete match.

### Example
The following example reads a text-file and echos a parsed result.

**File: capitals.txt**

	Sweden, Stockholm
	Spain, Madrid
	France, Paris

**Command:**

	$ cat capitals.txt | bux -l "/(\w+),\s?([\w\s]+)/i" "echo {2} is the capital of {1}"

**Output:**

	Stockholm is the capital of Sweden
	Madrid is the capital of Spain
	Paris is the capital of France

## Options

### Dry run
`-d` or `--dry-run`

It is often tricky to get your regular expression right the first time,
therefore `bux` will output the constructed commands to STDOUT instead if you
specify a dry run.

### Line by line
`-l` or `--lines`

Keeping lists of custom arguments can be very handy. `bux` allows you to execute
and merge the `command` for each line in STDIN individually (see *Example*).

## License
`bux` is licensed under [MIT][mit]

## Author

Carl Calderon: [@carlcalderon][twitter]

[twitter]:https://twitter.com/carlcalderon
[mit]:https://github.com/carlcalderon/bux/blob/master/LICENSE

