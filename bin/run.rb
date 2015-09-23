#!/usr/bin/env ruby
require 'pry'

# example arguments: ["Emailer", "main", "dev", "10"]

file = ARGV.shift

dir_path = File.expand_path File.dirname(__FILE__)

# go ahead and chdir to allow bundler loads to work
Dir.chdir(dir_path)

# move from bin to project lib
Dir.chdir("../lib")

file_path = File.expand_path(file, dir_path)

require file_path

klass = eval(ARGV.shift)
method = ARGV.shift.to_sym
# class method send
klass.send(method, *ARGV)
