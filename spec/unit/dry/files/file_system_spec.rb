# frozen_string_literal: true

require "dry/files/file_system"
require "securerandom"
require "English"

RSpec.describe Dry::Files::FileSystem do
  let(:root) { Pathname.new(Dir.pwd).join("tmp", SecureRandom.uuid).tap(&:mkpath) }
  let(:newline) { $INPUT_RECORD_SEPARATOR }

  after do
    FileUtils.remove_entry_secure(root)
  end

  describe "#touch" do
    it "creates an empty file" do
      path = root.join("touch")
      subject.touch(path)

      expect(path).to be_found
      expect(path).to have_file_contents("")
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "file", "touch")
      subject.touch(path)

      expect(path).to be_found
      expect(path).to have_file_contents("")
    end

    xit "leaves untouched existing file" do
      path = root.join("touch")
      subject.write(path, "foo")
      subject.touch(path)

      expect(path).to be_found
      expect(path).to have_file_contents("foo")
    end

    it "raises error if path is a directory" do
      path = root.join("touch-directory")
      subject.mkdir(path)

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
      subject.mkdir(path)

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

      expect(path).to be_found
      expect(path).to have_file_contents("Hello#{newline}World")
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "file", "write")
      subject.write(path, ":)")

      expect(path).to be_found
      expect(path).to have_file_contents(":)")
    end

    it "overwrites file when it already exist" do
      path = root.join("write")
      subject.write(path, "many many many many words")
      subject.write(path, "new words")

      expect(path).to be_found
      expect(path).to have_file_contents("new words")
    end

    xit "raises error when path isn't writeable" do
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
      subject.rm(source) if subject.exist?(source)
    end

    it "creates a file with given contents" do
      subject.write(source, "the source")

      destination = root.join("cp")
      subject.cp(source, destination)

      expect(destination).to be_found
      expect(destination).to have_file_contents("the source")
    end

    it "creates intermediate directories" do
      source = root.join("..", "source")
      subject.write(source, "the source for intermediate directories")

      destination = root.join("cp", "destination")
      subject.cp(source, destination)

      expect(destination).to be_found
      expect(destination).to have_file_contents("the source for intermediate directories")
    end

    it "overrides already existing file" do
      source = root.join("..", "source")
      subject.write(source, "the source")

      destination = root.join("cp")
      subject.write(destination, "the destination")
      subject.cp(source, destination)

      expect(destination).to be_found
      expect(destination).to have_file_contents("the source")
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
      expect(root.join(path)).to eq(path)

      path = Pathname.new(path)
      expect(root.join(path)).to eq(path.to_s)
    end

    it "joins multiple entries" do
      path = %w[path to file]
      expected = path.join(File::SEPARATOR)

      expect(root.join(path)).to eq(expected)

      path = path.map { |p| Pathname.new(p) }
      expect(root.join(path)).to eq(expected)
    end
  end

  xdescribe "#expand_path" do
    it "expands path from current directory" do
      path = "expand-path"

      begin
        subject.touch(path)

        expect(subject.expand_path(path, subject.pwd)).to eq(File.join(Dir.pwd, path))
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
    it "returns root directory by default" do
      expect(subject.pwd).to eq("/")
    end
  end

  describe "#chdir" do
    it "changes current working directory" do
      current_directory = subject.pwd
      subject.mkdir(dir = "path/to/dir")

      subject.chdir(dir) do
        expect(subject.pwd).to eq("dir")
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

      expect(subject.directory?(path)).to be(true)
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "mkdir")
      subject.mkdir(path)

      expect(subject.directory?(path)).to be(true)
    end

    xit "raises error when path isn't writeable" do
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
      path = root.join(directory, "file.rb")
      subject.mkdir_p(path)

      expect(subject.directory?(directory)).to be(true)
      expect(path).to_not be_found
    end

    it "creates intermediate directories" do
      directory = root.join("path", "to", "mkdir_p")
      path = root.join(directory, "file.rb")
      subject.mkdir_p(path)

      expect(subject.directory?(directory)).to be(true)
      expect(path).to_not be_found
    end

    xit "raises error when path isn't writeable" do
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

  describe "#rm" do
    it "deletes path" do
      path = root.join("delete", "file")
      subject.touch(path)
      subject.rm(path)

      expect(path).to_not be_found
    end

    it "raises error if path doesn't exist" do
      path = root.join("delete", "file")

      expect { subject.rm(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if path is a directory" do
      path = root.join("delete", "directory")
      subject.mkdir(path)

      expect { subject.rm(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EPERM)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#rm_rf" do
    it "deletes directory" do
      path = root.join("delete", "directory")
      subject.mkdir(path)
      subject.rm_rf(path)

      expect(path).to_not be_found
    end

    it "deletes a file" do
      path = root.join("delete_directory", "file")
      subject.touch(path)
      subject.rm_rf(path)

      expect(path).to_not be_found
    end

    it "raises error if directory doesn't exist" do
      path = root.join("delete", "directory")

      expect { subject.rm_rf(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#readlines" do
    it "reads file and returns array of lines" do
      path = root.join("readlines-file")
      subject.write(path, "hello#{newline}world")

      expect(subject.readlines(path)).to eq(%W[hello#{newline} world])
    end

    it "reads empty file and returns empty array" do
      path = root.join("readlines-empty-file")
      subject.touch(path)

      expect(subject.readlines(path)).to eq([])
    end

    it "raises error if file doesn't exist" do
      path = root.join("readlines-non-existing-file")

      expect { subject.readlines(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if path is a directory" do
      path = root.join("readlines", "directory")
      subject.mkdir(path)

      expect { subject.readlines(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EISDIR)
        expect(exception.message).to include(path.to_s)
      end
    end

    xit "it raises error if path isn't readable"
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

  xdescribe "#executable?" do
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
