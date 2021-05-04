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
