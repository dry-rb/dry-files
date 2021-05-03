---
title: Ruby File Manipulation
layout: gem-single
name: dry-files
---

### Ruby File Manipulation

``` ruby
# frozen_string_literal: true
require "dry/files"

path = "path/to/file.rb"

files = Dry::Files.new

# adds a new line at the top of the file
files.unshift(path, "# frozen_string_literal: true")

# adds a new line at the bottom of the file
files.append(path, "__END__")



# replace first line that match target
files.replace_first_line(path, "foo", "bar") # replace the first match of foo, with bar

# replace last line that match target
files.replace_last_line(path, "foo", "bar") # replace the last match of foo, with bar



# inject content before the first match of target
files.inject_line_before(path, "foo", "abc") # inject abc before the first match of foo

# inject content before the last match of target
files.inject_line_before_last(path, "foo", "abc") # inject abc before the last match of foo



# inject content after the first match of target
files.inject_line_after(path, "foo", "def") # inject def after the first match of foo

# inject content after the last match of target
files.inject_line_after_last(path, "foo", "def") # inject def after the last match of foo



# inject content as the first line of the matching code block
files.inject_line_at_block_top(path, "routes do", "route") # inject route, right after the routes block opening

# inject content as the last line of the matching code block
files.inject_line_at_block_bottom(path, "routes do", "route") # inject route, right after the routes block ending



# remove the first matching line
files.remove(line, "foo") # removes the first line that matches foo

# remove the first matching block
files.remove(line, "configure do") # removes the first block that matches configure
```
