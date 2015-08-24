#!/usr/bin/env bash

hash haxe 2>/dev/null || { echo >&2 "Haxe is missing. Please get it from http://haxe.org/"; exit 1; }

haxelib install hxcpp ;

haxe build.hxml ;

cp ./bin/bux /usr/local/bin/bux ;
