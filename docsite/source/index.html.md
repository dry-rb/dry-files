---
title: Introduction
description: File utilities
layout: gem-single
order: ???
type: gem
name: dry-files
sections:
  - file-system-utilities
  - ruby-file-manipulation
  - adapters
  - error-handling
---

dry-files is Ruby gem that provides a great abstraction for file manipulations.

### Basic usage

``` ruby
# frozen_string_literal: true
require "dry/files"

files = Dry::Files.new
files.write("path/to/file", "Hello, World!") # intermediate directories are created, if missing
```

### Features

``` ruby
# frozen_string_literal: true
require "dry/files"

path = "path/to/file"

files = Dry::Files.new

# open the file both for read/write operations
# create the file and intermediate directories if they not exist
files.open(path) do |file|
  file.read
  file.write("foo")
end

# read the file all at once, returning a string
files.read(path)

# read the file all at once, returning an array of lines
files.readlines(path)

# touch a file
# create the intermediate directories if they not exist
files.touch(path)

# write a file
# create the intermediate directories if they not exist
# if the file exists, replace the contents
files.write(path, "hello")

# join the given paths
files.join("path", "to", "file")
files.join("path", ["to", "file"])
files.join("path/to/file")

# expand the given path
# the base directory is the current one
# you can specify a base directory
files.expand_path(path) # base dir is Dir.pwd (implict)
files.expand_path(path, "path/to/base/directory")

# returns the path to the current directory
files.pwd

# temporary changes the current directory
files.chdir("path/to/dir") do
  files.pwd # => "path/to/dir"
end

# creates intermediate directories for the given path (directory)
files.mkdir("path/to/new/dir")

# creates intermediate directories for the given path (file)
files.mkdir_p("path/to/new/dir/file.rb") # creates "path/to/new/dir"

# copy source file to destination
# intermediate destination directories are created if they not exist
file.cp(path, "path/to/destination")

# delete a file
file.delete(path)

# delete a directory
file.delete_directory("path/to/dir")

# check if path exist (files and directories)
file.exist?(path)

# check if path is a directory
file.directory?(path)

# check if path is an executable (files and directories)
file.executable?(path)
```

### Adapters

dry-files ships with two adapters:

  * File System adapter (default), for real file manipulation. It's meant to be used in production and integration tests.
  * Memory adapter, for in-memory file manipulation. It's meant to be used for unit test.

``` ruby
# frozen_string_literal: true
require "dry/files"

files = Dry::Files.new(memory: true)
files.write("path/to/file", "Hello, World!") # create a file in-memory
```
