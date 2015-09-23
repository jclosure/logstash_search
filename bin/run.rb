#!/usr/bin/env ruby
require 'pry'

# example arguments: ["Emailer", "main", "dev", "10"]

file = ARGV.shift

project_root_path = File.expand_path("#{File.dirname(__FILE__)}/..")

# go ahead and chdir to allow bundler loads to work
Dir.chdir(project_root_path)

project_lib_path = File.expand_path("#{project_root_path}/lib")

# setup load path
$:.unshift(project_root_path) unless
    $:.include?(project_root_path)
$:.unshift(project_lib_path) unless
    $:.include?(project_lib_path)


require file

klass = eval(ARGV.shift)
method = ARGV.shift.to_sym
# class method send
klass.send(method, *ARGV)
