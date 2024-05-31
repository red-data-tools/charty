#!/usr/bin/env ruby

# TODO
# $VERBOSE = true

require "pathname"

base_dir = Pathname(__dir__).parent.expand_path

lib_dir = base_dir + "lib"
test_dir = base_dir + "test"
test_lib_dir = test_dir + "lib"

$LOAD_PATH.unshift(lib_dir.to_s)
$LOAD_PATH.unshift(test_lib_dir.to_s)

require_relative "helper"

exit(Test::Unit::AutoRunner.run(true, test_dir.to_s))
