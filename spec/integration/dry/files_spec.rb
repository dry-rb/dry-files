# frozen_string_literal: true

require "securerandom"
require "English"

RSpec.describe Dry::Files do
  let(:root) { Pathname.new(Dir.pwd).join("tmp", SecureRandom.uuid).tap(&:mkpath) }
  let(:newline) { $INPUT_RECORD_SEPARATOR }

  after do
    FileUtils.remove_entry_secure(root)
  end

  describe "#touch" do
    it "creates an empty file" do
      path = root.join("touch")
      subject.touch(path)

      expect(path).to exist
      expect(path).to have_content("")
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "file", "touch")
      subject.touch(path)

      expect(path).to exist
      expect(path).to have_content("")
    end

    it "leaves untouched existing file" do
      path = root.join("touch")
      path.open("wb+") { |p| p.write("foo") }
      subject.touch(path)

      expect(path).to exist
      expect(path).to have_content("foo")
    end

    it "raises error if path is a directory" do
      path = root.join("touch-directory")
      path.mkpath

      expect { subject.touch(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EISDIR)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#read" do
    it "reads file" do
      path = root.join("read")
      subject.write(path, expected = "Hello#{newline}World")

      expect(subject.read(path)).to eq(expected)
    end

    it "raises error when path is a directory" do
      path = root.join("read-directory")
      path.mkpath

      expect { subject.read(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EISDIR)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error when path doesn't exist" do
      path = root.join("read-does-not-exist")

      expect { subject.read(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#write" do
    it "creates an file with given contents" do
      path = root.join("write")
      subject.write(path, "Hello#{newline}World")

      expect(path).to exist
      expect(path).to have_content("Hello#{newline}World")
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "file", "write")
      subject.write(path, ":)")

      expect(path).to exist
      expect(path).to have_content(":)")
    end

    it "overwrites file when it already exists" do
      path = root.join("write")
      subject.write(path, "many many many many words")
      subject.write(path, "new words")

      expect(path).to exist
      expect(path).to have_content("new words")
    end

    it "raises error when path isn't writeable" do
      path = root.join("write-not-writeable")
      path.mkpath
      mode = path.stat.mode

      begin
        path.chmod(0o000)

        expect { subject.write(path.join("file-not-writeable"), "content") }.to raise_error do |exception|
          expect(exception).to be_kind_of(Dry::Files::IOError)
          expect(exception.cause).to be_kind_of(Errno::EACCES)
          expect(exception.message).to include(path.to_s)
        end
      ensure
        path.chmod(mode)
      end
    end
  end

  describe "#cp" do
    let(:source) { root.join("..", "source") }

    before do
      source.delete if source.exist?
    end

    it "creates a file with given contents" do
      subject.write(source, "the source")

      destination = root.join("cp")
      subject.cp(source, destination)

      expect(destination).to exist
      expect(destination).to have_content("the source")
    end

    it "creates intermediate directories" do
      source = root.join("..", "source")
      subject.write(source, "the source for intermediate directories")

      destination = root.join("cp", "destination")
      subject.cp(source, destination)

      expect(destination).to exist
      expect(destination).to have_content("the source for intermediate directories")
    end

    it "overrides already existing file" do
      source = root.join("..", "source")
      subject.write(source, "the source")

      destination = root.join("cp")
      subject.write(destination, "the destination")
      subject.cp(source, destination)

      expect(destination).to exist
      expect(destination).to have_content("the source")
    end

    it "raises error when source cannot be found" do
      source = root.join("missing-source")
      destination = root.join("cp")

      expect { subject.cp(source, destination) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(source.to_s)
      end
    end
  end

  describe "#join" do
    it "joins a single entry" do
      path = "path"
      expect(subject.join(path)).to eq(path)

      path = Pathname.new(path)
      expect(subject.join(path)).to eq(path.to_s)
    end

    it "joins multiple entries" do
      path = %w[path to file]
      expected = path.join(File::SEPARATOR)

      expect(subject.join(path)).to eq(expected)

      path = path.map { |p| Pathname.new(p) }
      expect(subject.join(path)).to eq(expected)
    end
  end

  describe "#expand_path" do
    it "expands path from current directory" do
      path = "expand-path"

      begin
        subject.touch(path)

        expect(subject.expand_path(path)).to eq(File.join(Dir.pwd, path))
      ensure
        FileUtils.rm_rf(path)
      end
    end

    it "expands path from current directory in combination with chdir" do
      path = root.join("expand-path", "dir", "file")
      subject.touch(path)

      subject.chdir(root.join("expand-path", "dir")) do
        expect(subject.expand_path("file")).to eq(path.realpath.to_s)
      end
    end

    it "expands path from given directory" do
      dir = root.join("expand-path", "given-dir")
      path = dir.join("file")
      subject.touch(path)

      expect(subject.expand_path("file", dir)).to eq(path.realpath.to_s)
    end

    it "returns absolute path as it is" do
      path = root.join("expand-path", "absolute")
      subject.touch(path)

      expect(subject.expand_path(path.realpath)).to eq(path.realpath.to_s)
    end
  end

  describe "#pwd" do
    it "returns current working directory" do
      expect(subject.pwd).to eq(Dir.pwd)
    end

    it "returns current working directory in combination with Dir.chdir" do
      Dir.chdir(root) do
        expect(subject.pwd).to eq(root.to_s)
      end
    end
  end

  describe "#chdir" do
    it "changes current working directory" do
      current_directory = Dir.pwd
      expect(subject.pwd).to eq(current_directory)

      subject.chdir(root) do
        expect(subject.pwd).to eq(root.to_s)
        expect(Dir.pwd).to eq(root.to_s)
      end

      expect(subject.pwd).to eq(current_directory)
    end

    it "raises error if directory cannot be found" do
      path = root.join("chdir-non-existing")

      expect { subject.chdir(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if argument is a file" do
      path = root.join("chdir-file")
      subject.touch(path)

      expect { subject.chdir(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOTDIR)
        expect(exception.message).to match(path.to_s)
      end
    end
  end

  describe "#mkdir" do
    it "creates directory" do
      path = root.join("mkdir")
      subject.mkdir(path)

      expect(path).to be_directory
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "mkdir")
      subject.mkdir(path)

      expect(path).to be_directory
    end

    it "raises error when path isn't writeable" do
      path = root.join("mkdir-not-writeable")
      path.mkpath
      mode = path.stat.mode

      begin
        path.chmod(0o000)

        expect { subject.mkdir(path.join("dir-not-writeable")) }.to raise_error do |exception|
          expect(exception).to be_kind_of(Dry::Files::IOError)
          expect(exception.cause).to be_kind_of(Errno::EACCES)
          expect(exception.message).to include(path.to_s)
        end
      ensure
        path.chmod(mode)
      end
    end
  end

  describe "#mkdir_p" do
    it "creates directory" do
      directory = root.join("mkdir_p")
      path = directory.join("file.rb")
      subject.mkdir_p(path)

      expect(directory).to be_directory
      expect(path).to_not  exist
    end

    it "creates intermediate directories" do
      directory = root.join("path", "to", "mkdir_p")
      path = directory.join("file.rb")
      subject.mkdir_p(path)

      expect(directory).to be_directory
      expect(path).to_not  exist
    end

    it "raises error when path isn't writeable" do
      parent = root.join("path")
      parent.mkpath
      mode = parent.stat.mode

      begin
        parent.chmod(0o000)
        path = parent.join("to", "mkdir_p", "dir-not-writeable")

        expect { subject.mkdir_p(path) }.to raise_error do |exception|
          expect(exception).to be_kind_of(Dry::Files::IOError)
          expect(exception.cause).to be_kind_of(Errno::EACCES)
          expect(exception.message).to include(parent.to_s)
        end
      ensure
        parent.chmod(mode)
      end
    end
  end

  describe "#delete" do
    it "deletes path" do
      path = root.join("delete", "file")
      subject.touch(path)
      subject.delete(path)

      expect(path).to_not exist
    end

    it "raises error if path doesn't exist" do
      path = root.join("delete", "file")

      expect { subject.delete(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if path is a directory" do
      path = root.join("delete", "directory")
      path.mkpath

      expect { subject.delete(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)

        with_ruby_engine(:mri) do
          with_operating_system(:macos) do
            expect(exception.cause).to be_kind_of(Errno::EPERM)
          end

          with_operating_system(:linux) do
            expect(exception.cause).to be_kind_of(Errno::EISDIR)
          end
        end

        with_ruby_engine(:jruby) do
          expect(exception.cause).to be_kind_of(Errno::EPERM)
        end

        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#delete_directory" do
    it "deletes directory" do
      path = root.join("delete_directory", "directory")
      subject.mkdir(path)
      subject.delete_directory(path)

      expect(path).to_not exist
    end

    it "deletes a file" do
      path = root.join("delete_directory", "file")
      subject.touch(path)
      subject.delete_directory(path)

      expect(path).to_not exist
    end

    it "raises error if directory doesn't exist" do
      path = root.join("delete_directory", "directory")

      expect { subject.delete_directory(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#unshift" do
    it "adds a line at the top of the file" do
      path = root.join("unshift.rb")
      content = <<~CONTENT
        class Unshift
        end
      CONTENT

      subject.write(path, content)
      subject.unshift(path, "# frozen_string_literal: true")

      expected = <<~CONTENT
        # frozen_string_literal: true
        class Unshift
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    # https://github.com/hanami/utils/issues/348
    it "adds a line at the top of a file that doesn't end with a newline" do
      path = root.join("unshift_missing_newline.rb")
      content = "get '/tires', to: 'sunshine#index'"

      subject.write(path, content)
      subject.unshift(path, "root to: 'home#index'")

      expected = "root to: 'home#index'#{newline}get '/tires', to: 'sunshine#index'"

      expect(path).to have_content(expected)
    end

    it "raises error if path doesn't exist" do
      path = root.join("unshift_no_exist.rb")

      expect { subject.unshift(path, "# frozen_string_literal: true") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#append" do
    it "adds a line at the bottom of the file" do
      path = root.join("append.rb")
      content = <<~CONTENT
        class Append
        end
      CONTENT

      subject.write(path, content)
      subject.append(path, "#{newline}Foo.register Append")

      expected = <<~CONTENT
        class Append
        end

        Foo.register Append
      CONTENT

      expect(path).to have_content(expected)
    end

    it "does not add multiple newlines to the bottom of the file" do
      path = root.join("append.rb")
      content = <<~CONTENT
        class Append
        end
      CONTENT

      subject.write(path, content)
      subject.append(path, "#{newline}Foo.register Append\n")

      expected = <<~CONTENT
        class Append
        end

        Foo.register Append
      CONTENT

      expect(path).to have_content(expected)
    end

    it "adds a line at the bottom of a file that doesn't end with a newline" do
      path = root.join("append_missing_newline.rb")
      content = "root to: 'home#index'"

      subject.write(path, content)
      subject.append(path, "get '/tires', to: 'sunshine#index'")

      expected = <<~CONTENT
        root to: 'home#index'
        get '/tires', to: 'sunshine#index'
      CONTENT

      expect(path).to have_content(expected)
    end

    it "creates a file, if it doesn't exist" do
      path = root.join("path", "to", "Gemfile")
      content = <<~CONTENT
        group :test do
          gem "capybara"
        end
      CONTENT

      subject.append(path, content)

      expect(subject.read(path)).to include(content)
    end
  end

  describe "#replace_first_line" do
    it "replaces string target with replacement" do
      path = root.join("replace_string.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_first_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class Replace
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces regexp target with replacement" do
      path = root.join("replace_regexp.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_first_line(path, /perform/, "  def self.call(input)")

      expected = <<~CONTENT
        class Replace
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces only the first occurrence of target with replacement" do
      path = root.join("replace_first.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end

          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_first_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class Replace
          def self.call(input)
          end

          def self.perform
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("replace_not_found.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.replace_first_line(path, "not existing target", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("replace_no_exist.rb")

      expect { subject.replace_first_line(path, "perform", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#replace_last_line" do
    it "replaces string target with replacement" do
      path = root.join("replace_last_string.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_last_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class ReplaceLast
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces regexp target with replacement" do
      path = root.join("replace_last_regexp.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_last_line(path, /perform/, "  def self.call(input)")

      expected = <<~CONTENT
        class ReplaceLast
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces only the last occurrence of target with replacement" do
      path = root.join("replace_last.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end

          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_last_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class ReplaceLast
          def self.perform
          end

          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("replace_last_not_found.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.replace_last_line(path, "not existing target", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("replace_last_no_exist.rb")

      expect { subject.replace_last_line(path, "perform", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_before" do
    it "injects line before target (string)" do
      path = root.join("inject_before_string.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before(path, "call", "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line before target (regexp)" do
      path = root.join("inject_before_regexp.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before(path, /call/, "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_before_not_found.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_before(path, "not existing target", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_before_no_exist.rb")

      expect { subject.inject_line_before(path, "call", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_before_last" do
    it "injects line before last target (string)" do
      path = root.join("inject_before_last_string.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before_last(path, "call", "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          def self.call
          end
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line before last target (regexp)" do
      path = root.join("inject_before_last_regexp.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before_last(path, /call/, "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          def self.call
          end
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_before_last_not_found.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_before_last(path, "not existing target", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_before_last_no_exist.rb")

      expect { subject.inject_line_before_last(path, "call", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_after" do
    it "injects line after target (string)" do
      path = root.join("inject_after.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after(path, "call", "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line after target (regexp)" do
      path = root.join("inject_after.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after(path, /call/, "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_after_not_found.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_after(path, "not existing target", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_after_no_exist.rb")

      expect { subject.inject_line_after(path, "call", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_after_last" do
    it "injects line after last target (string)" do
      path = root.join("inject_after_last.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after_last(path, "call", "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line after last target (regexp)" do
      path = root.join("inject_after_last.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after_last(path, /call/, "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_after_last_not_found.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_after_last(path, "not existing target", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_after_last_no_exist.rb")

      expect { subject.inject_line_after_last(path, "call", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#remove_line" do
    it "removes line (string)" do
      path = root.join("remove_line_string.rb")
      content = <<~CONTENT
        # frozen_string_literal: true
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_line(path, "frozen")

      expected = <<~CONTENT
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "removes line (regexp)" do
      path = root.join("remove_line_regexp.rb")
      content = <<~CONTENT
        # frozen_string_literal: true
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_line(path, /frozen/)

      expected = <<~CONTENT
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("remove_line_not_found.rb")
      content = <<~CONTENT
        # frozen_string_literal: true
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.remove_line(path, "not existing target") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("remove_line_no_exist.rb")

      expect { subject.remove_line(path, "frozen") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_at_block_top" do
    it "injects line at the top of the Ruby block" do
      path = root.join("inject_line_at_block_top.rb")
      content = <<~CONTENT
        class InjectLineBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "configure", %(load_path.unshift("dir")))

      expected = <<~CONTENT
        class InjectLineBlockTop
          configure do
            load_path.unshift("dir")
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line at the top of the Ruby block (using a Regexp matcher)" do
      path = root.join("inject_line_regexp_at_block_top.rb")
      content = <<~CONTENT
        class InjectLineRegexpBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_top(path, /configure/, %(load_path.unshift("dir")))

      expected = <<~CONTENT
        class InjectLineRegexpBlockTop
          configure do
            load_path.unshift("dir")
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects lines at the top of the Ruby block" do
      path = root.join("inject_lines_at_block_top.rb")
      content = <<~CONTENT
        class InjectLinesBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "configure", [%(load_path.unshift("dir")), "settings.load!"])

      expected = <<~CONTENT
        class InjectLinesBlockTop
          configure do
            load_path.unshift("dir")
            settings.load!
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects block at the top of the Ruby block" do
      path = root.join("inject_block_at_block_top.rb")
      content = <<~CONTENT
        class InjectBlockBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      block = <<~BLOCK
        settings do
          load!
        end
      BLOCK

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "configure", block)

      expected = <<~CONTENT
        class InjectBlockBlockTop
          configure do
            settings do
              load!
            end
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects block at the top of the nested Ruby block" do
      path = root.join("inject_block_at_nested_block_top.rb")
      content = <<~CONTENT
        class InjectBlockBlockTop
          configure do
            routes do
              resources :books do
                get "/discounted", to: "books.discounted"
              end
            end
          end
        end
      CONTENT

      block = <<~BLOCK
        root { "Hello" }
      BLOCK

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "routes", block)

      expected = <<~CONTENT
        class InjectBlockBlockTop
          configure do
            routes do
              root { "Hello" }
              resources :books do
                get "/discounted", to: "books.discounted"
              end
            end
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if file cannot be found" do
      path = root.join("inject_line_at_block_top_missing_file.rb")

      expect { subject.inject_line_at_block_top(path, "configure", "") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if Ruby block cannot be found" do
      path = root.join("inject_line_at_block_top_missing_block.rb")

      content = <<~CONTENT
        class InjectLineBlockTopMissingBlock
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_at_block_top(path, "configure", "") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `configure' in `#{path.realpath}'")
      end
    end
  end

  describe "#inject_line_at_block_bottom" do
    it "injects line at the bottom of the Ruby block" do
      path = root.join("inject_line_at_block_bottom.rb")
      content = <<~CONTENT
        class InjectLineBlockBottom
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, "configure", %(load_path.unshift("dir")))

      expected = <<~CONTENT
        class InjectLineBlockBottom
          configure do
            root __dir__
            load_path.unshift("dir")
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line at the bottom of the Ruby block (ignoring false positive blocks)" do
      path = root.join("inject_line_at_block_bottom_gemfile.rb")
      content = <<~CONTENT
        group :development do
          gem "hanami-webconsole"
        end

        group :development, :test do
          gem "dotenv"
        end

        group :cli, :development do
          gem "hanami-reloader"
        end

        group :cli, :development, :test do
          gem "hanami-rspec"
        end

        group :test do
          gem "rack-test"
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, "group :development do", %(gem "guard-puma"))

      expected = <<~CONTENT
        group :development do
          gem "hanami-webconsole"
          gem "guard-puma"
        end

        group :development, :test do
          gem "dotenv"
        end

        group :cli, :development do
          gem "hanami-reloader"
        end

        group :cli, :development, :test do
          gem "hanami-rspec"
        end

        group :test do
          gem "rack-test"
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line at the bottom of the Ruby block (using a Regexp matcher)" do
      path = root.join("inject_line_regexp_at_block_bottom.rb")
      content = <<~CONTENT
        class InjectLineRegexpBlockBottom
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, /configure/, %(load_path.unshift("dir")))

      expected = <<~CONTENT
        class InjectLineRegexpBlockBottom
          configure do
            root __dir__
            load_path.unshift("dir")
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects lines at the bottom of the Ruby block" do
      path = root.join("inject_lines_at_block_bottom.rb")
      content = <<~CONTENT
        class InjectLinesBlockBottom
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, "configure", [%(load_path.unshift("dir")), "settings.load!"])

      expected = <<~CONTENT
        class InjectLinesBlockBottom
          configure do
            root __dir__
            load_path.unshift("dir")
            settings.load!
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects block at the bottom of the Ruby block" do
      path = root.join("inject_block_at_block_bottom.rb")
      content = <<~CONTENT
        class InjectBlockBlockBottom
          configure do
            root __dir__
          end
        end
      CONTENT

      block = <<~BLOCK
        settings do
          load!
        end
      BLOCK

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, "configure", block)

      expected = <<~CONTENT
        class InjectBlockBlockBottom
          configure do
            root __dir__
            settings do
              load!
            end
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects block at the bottom of the nested Ruby block" do
      path = root.join("inject_block_at_nested_block_bottom.rb")
      content = <<~CONTENT
        class Routes
          define do
            root { "Hello" }

            slice :foo, at: "/foo" do
            end
          end
        end
      CONTENT

      block_one = <<~BLOCK

        slice :bar, at: "/bar" do
        end
      BLOCK

      block_two = <<~BLOCK

        slice :baz, at: "/baz" do
        end
      BLOCK

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, "define", block_one)
      subject.inject_line_at_block_bottom(path, "define", block_two)

      expected = <<~CONTENT
        class Routes
          define do
            root { "Hello" }

            slice :foo, at: "/foo" do
            end

            slice :bar, at: "/bar" do
            end

            slice :baz, at: "/baz" do
            end
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects block at the bottom of the deeply nested Ruby block" do
      path = root.join("inject_block_at_deeply_nested_block_bottom.rb")
      content = <<~CONTENT
        class Routes
          define do
            root { "Hello" }

            slice :foo, at: "/foo" do
            end
          end
        end
      CONTENT

      input = <<~BLOCK
        get "/users", to: "users.index"
      BLOCK

      subject.write(path, content)
      subject.inject_line_at_block_bottom(path, "slice :foo", input)

      expected = <<~CONTENT
        class Routes
          define do
            root { "Hello" }

            slice :foo, at: "/foo" do
              get "/users", to: "users.index"
            end
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if file cannot be found" do
      path = root.join("inject_line_at_block_bottom_missing_file.rb")

      expect { subject.inject_line_at_block_bottom(path, "configure", "") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if Ruby block cannot be found" do
      path = root.join("inject_line_at_block_bottom_missing_block.rb")

      content = <<~CONTENT
        class InjectLineBlockBottomMissingBlock
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_at_block_top(path, "configure", "") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `configure' in `#{path.realpath}'")
      end
    end
  end

  describe "#remove_block" do
    it "removes block from Ruby file" do
      path = root.join("remove_block_simple.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_block(path, "configure")

      expected = <<~CONTENT
        class RemoveBlock
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "removes nested block from Ruby file" do
      path = root.join("remove_block_simple.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__

            assets do
              sources << [
                "path/to/sources"
              ]
            end
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_block(path, "assets")

      expected = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__

          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises an error when the file was not found" do
      path = root.join("remove_block_not_found.rb")

      expect { subject.remove_block(path, "configure") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if block cannot be found" do
      path = root.join("remove_block_string_simple.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.remove_block(path, "not existing target") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::MissingTargetError)
        expect(exception.message).to eq("cannot find `not existing target' in `#{path}'")
      end

      expect(path).to have_content(content)
    end
  end

  describe "#inject_line_at_class_bottom" do
    it "injects line at the bottom of the class" do
      path = root.join("inject_line_at_class_bottom.rb")
      content = <<~CONTENT
        class InjectLineClassBottom
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_class_bottom(path, "InjectLineClassBottom", "attr_accessor :foo")

      expected = <<~CONTENT
        class InjectLineClassBottom
          attr_accessor :foo
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line at the bottom of the class when there class level blocks" do
      path = root.join("inject_line_at_class_with_blocks_bottom.rb")
      content = <<~CONTENT
        class InjectLineClassWithBlocksBottom
          configure do
            setting :db do
              setting :url
            end
          end

          wrap { |context| }
          wrap { |ctx, env|
            env.each_key do |key|
            end
          }
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_class_bottom(path, "InjectLineClassWithBlocksBottom", "attr_accessor :foo")

      expected = <<~CONTENT
        class InjectLineClassWithBlocksBottom
          configure do
            setting :db do
              setting :url
            end
          end

          wrap { |context| }
          wrap { |ctx, env|
            env.each_key do |key|
            end
          }
          attr_accessor :foo
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line at the bottom of the module + class" do
      path = root.join("inject_line_at_module_plus_class_bottom.rb")
      content = <<~CONTENT
        module Foo
          class Bar
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_class_bottom(path, "Bar", "attr_accessor :foo")

      expected = <<~CONTENT
        module Foo
          class Bar
            attr_accessor :foo
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line at the bottom of the module + class and blocks" do
      path = root.join("inject_line_at_module_plus_class_and_blocks_bottom.rb")
      content = <<~CONTENT
        module Foo
          class Bar
            configure do
              setting :db do
                setting :url
              end
            end
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_class_bottom(path, "Bar", "attr_accessor :foo")

      expected = <<~CONTENT
        module Foo
          class Bar
            configure do
              setting :db do
                setting :url
              end
            end
            attr_accessor :foo
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    xit "injects line at the bottom of the class with inner classes and modules" do
      path = root.join("inject_line_at_class_bottom.rb")
      content = <<~CONTENT
        class InjectLineClassWithInnerClassesBottom
          module ClassMethods
          end

          module Mixin
            included do |base|
              base.extend(ClassMethods)
            end
          end

          class Result
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_class_bottom(path, "InjectLineClassWithInnerClassesBottom", "attr_accessor :foo")

      expected = <<~CONTENT
        class InjectLineClassWithInnerClassesBottom
          module ClassMethods
          end

          module Mixin
            included do |base|
              base.extend(ClassMethods)
            end
          end

          class Result
          end
          attr_accessor :foo
        end
      CONTENT

      expect(path).to have_content(expected)
    end
  end

  describe "#exist?" do
    it "returns true for file" do
      path = root.join("exist-file")
      subject.touch(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns true for directory" do
      path = root.join("exist-dir")
      subject.mkdir(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns false for non-existing file" do
      path = root.join("exist-non-existing")

      expect(subject.exist?(path)).to be(false)
    end
  end

  describe "#directory?" do
    it "returns true for directory" do
      path = root.join("directory-dir")
      subject.mkdir(path)

      expect(subject.directory?(path)).to be(true)
    end

    it "returns false for file" do
      path = root.join("directory-file")
      subject.touch(path)

      expect(subject.directory?(path)).to be(false)
    end

    it "returns false for non-existing path" do
      path = root.join("directory-non-existing")

      expect(subject.directory?(path)).to be(false)
    end
  end

  describe "#executable?" do
    it "returns true when file is executable" do
      path = root.join("executable-exec")
      subject.touch(path)
      path.chmod(0o744)

      expect(subject.executable?(path)).to be(true)
    end

    it "returns false when file isn't executable" do
      path = root.join("executable-non-exec")
      subject.touch(path)

      expect(subject.executable?(path)).to be(false)
    end

    it "returns false when file doesn't exist" do
      path = root.join("executable-non-existing")

      expect(subject.executable?(path)).to be(false)
    end

    it "returns true for directory" do
      path = root.join("executable-directory")
      subject.mkdir(path)

      expect(subject.executable?(path)).to be(true)
    end
  end
end
