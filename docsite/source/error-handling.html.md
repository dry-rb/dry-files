---
title: Error Handling
layout: gem-single
name: dry-files
---

### Error Handling

dry-files raises custom errors for its operations

  * `Dry::Files::Error` base error
  * `Dry::Files::IOError` I/O error

### `Dry::Files::Error`

It's the base error. We suggest to catch it.
By doing so, you'll also catch all the exceptions that dry-files will raise.

``` ruby
# frozen_string_literal: true
require "dry/files"

files = Dry::Files.new

begin
  files.read("path/to/directory")
rescue Dry::Files::Error => exception
  # rescue all the dry-files exceptions
end
```

### `Dry::Files::IOError`

It wraps Ruby I/O errors such as `Errno::ENOENT`.
All the adapters raise `Dry::Files::IOError` to provide a consistent user experience.

``` ruby
# frozen_string_literal: true
require "dry/files"

files = Dry::Files.new

begin
  files.read("path/to/directory")
rescue Dry::Files::Error => exception
  exception.class # => Dry::Files::IOError
  exception.cause # => Errno::EISDIR
  exception.message # => "Is a directory - path/to/directory"
end
```

### `Dry::Files::MissingTargetError`

This is used by Ruby File Manipulation features to signal that the given matcher doesn't exist in Ruby code.

Given the following file: `foo.rb`

```ruby
# frozen_string_literal: true

class Foo
  def call
  end
end
```

``` ruby
# frozen_string_literal: true
require "dry/files"

files = Dry::Files.new

begin
  files.inject_line_before("foo.rb", "run", "private")
rescue Dry::Files::Error => exception
  exception.class # => Dry::Files::MissingTargetError
  exception.message # => "cannot find `run' in `foo.rb'"
end
```
