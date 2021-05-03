---
title: Adapters
layout: gem-single
name: dry-files
---

### Adapters

dry-files ships with two adapters:

  * File System adapter (default), for real file manipulation. It's meant to be used in production and integration tests.
  * Memory adapter (experimental), for in-memory file manipulation. It's meant to be used for unit test.

``` ruby
# frozen_string_literal: true
require "dry/files"

files = Dry::Files.new(memory: true)
files.write("path/to/file", "Hello, World!") # create a file in-memory
```
