# frozen_string_literal: true

require "dry/files/memory_file_system"
require "English"

RSpec.describe Dry::Files::MemoryFileSystem do
  let(:newline) { $INPUT_RECORD_SEPARATOR }

  describe "#initialize" do
    it "returns a new instance" do
      expect(subject).to be_kind_of(described_class)
    end
  end

  describe "#open" do
    context "when file doesn't exist" do
      it "creates file with empty content and yields node" do
        path = subject.join("open-new")

        subject.open(path) do |file|
          expect(file).to be_kind_of(Dry::Files::MemoryFileSystem::Node)
        end

        expect(path).to have_file_contents("")
      end
    end

    context "when already exist" do
      it "creates file with empty content and yields node" do
        path = subject.join("open-non-existing")
        subject.write("open-non-existing", content = "foo")

        subject.open(path) do |file|
          expect(file).to be_kind_of(Dry::Files::MemoryFileSystem::Node)
        end

        expect(path).to have_file_contents(content)
      end
    end
  end

  describe "#read" do
    it "reads file" do
      path = subject.join("read")
      subject.write(path, expected = "Hello#{newline}World")

      expect(subject.read(path)).to eq(expected)
    end

    it "raises error when path is a directory" do
      path = subject.join("read-directory")
      subject.mkdir(path)

      expect { subject.read(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EISDIR)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error when path doesn't exist" do
      path = subject.join("read-does-not-exist")

      expect { subject.read(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#readlines" do
    it "reads file and returns array of lines" do
      path = subject.join("readlines-file")
      subject.write(path, "hello#{newline}world")

      expect(subject.readlines(path)).to eq(%W[hello#{newline} world])
    end

    it "reads empty file and returns empty array" do
      path = subject.join("readlines-empty-file")
      subject.touch(path)

      expect(subject.readlines(path)).to eq([])
    end

    it "raises error if file doesn't exist" do
      path = subject.join("readlines-non-existing-file")

      expect { subject.readlines(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if path is a directory" do
      path = subject.join("readlines", "directory")
      subject.mkdir(path)

      expect { subject.readlines(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EISDIR)
        expect(exception.message).to include(path.to_s)
      end
    end

    xit "it raises error if path isn't readable"
  end

  describe "#touch" do
    it "creates an empty file" do
      path = subject.join("touch")
      subject.touch(path)

      expect(path).to be_found
      expect(path).to have_file_contents("")
    end

    it "creates intermediate directories" do
      path = subject.join("path", "to", "file", "touch")
      subject.touch(path)

      expect(path).to be_found
      expect(path).to have_file_contents("")
    end

    it "leaves untouched existing file" do
      path = subject.join("touch")
      subject.write(path, "foo")
      subject.touch(path)

      expect(path).to be_found
      expect(path).to have_file_contents("foo")
    end

    it "raises error if path is a directory" do
      path = subject.join("touch-directory")
      subject.mkdir(path)

      expect { subject.touch(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EISDIR)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#write" do
    it "creates an file with given contents" do
      path = subject.join("write")
      subject.write(path, "Hello#{newline}World")

      expect(path).to be_found
      expect(path).to have_file_contents("Hello#{newline}World")
    end

    it "creates intermediate directories" do
      path = subject.join("path", "to", "file", "write")
      subject.write(path, ":)")

      expect(path).to be_found
      expect(path).to have_file_contents(":)")
    end

    it "overwrites file when it already exist" do
      path = subject.join("write")
      subject.write(path, "many many many many words")
      subject.write(path, "new words")

      expect(path).to be_found
      expect(path).to have_file_contents("new words")
    end

    xit "raises error when path isn't writeable" do
      path = subject.join("write-not-writeable")
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
    it "expands path from given directory" do
      dir = subject.join("expand-path", "given-dir")
      expected = subject.join(dir, path = "file")

      expect(subject.expand_path(path, dir)).to eq(expected)
    end

    it "returns absolute path as it is" do
      path = ::File::SEPARATOR + subject.join("expand-path", "absolute")
      expect(subject.expand_path(path, subject.pwd)).to eq(path)
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
      path = subject.join("chdir-non-existing")

      expect { subject.chdir(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if argument is a file" do
      path = subject.join("chdir-file")
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
      path = subject.join("mkdir")
      subject.mkdir(path)

      expect(subject.directory?(path)).to be(true)
    end

    it "creates intermediate directories" do
      path = subject.join("path", "to", "mkdir")
      subject.mkdir(path)

      expect(subject.directory?(path)).to be(true)
    end

    it "raises error when path is a file" do
      path = subject.join("mkdir-is-file")
      subject.write(path, content = "foo")

      expect { subject.mkdir(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EEXIST)
        expect(exception.message).to include(path.to_s)
      end

      # ensure it doesn't override already existing file
      expect(subject.directory?(path)).to be(false)
      expect(subject.read(path)).to eq(content)
    end

    xit "raises error when path isn't writeable" do
      path = subject.join("mkdir-not-writeable")
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
      directory = subject.join("mkdir_p")
      path = subject.join(directory, "file.rb")
      subject.mkdir_p(path)

      expect(subject.directory?(directory)).to be(true)
      expect(path).to_not be_found
    end

    it "creates intermediate directories" do
      directory = subject.join("path", "to", "mkdir_p")
      path = subject.join(directory, "file.rb")
      subject.mkdir_p(path)

      expect(subject.directory?(directory)).to be(true)
      expect(path).to_not be_found
    end

    # It fails due to an RSpec formatter that crashes
    xit "raises error when path is a file" do
      file = subject.join("mkdir_p", "file")
      subject.write(file, content = "foo")
      path = subject.join(file, "nested")

      expect { subject.mkdir_p(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::EEXIST)
        expect(exception.message).to include(path.to_s)
      end

      # ensure it doesn't override already existing file
      expect(subject.directory?(path)).to be(false)
      expect(subject.read(path)).to eq(content)
    end

    xit "raises error when path isn't writeable" do
      parent = subject.join("path")
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

  describe "#cp" do
    let(:source) { subject.join("..", "source") }

    before do
      subject.rm(source) if subject.exist?(source)
    end

    it "creates a file with given contents" do
      subject.write(source, "the source")

      destination = subject.join("cp")
      subject.cp(source, destination)

      expect(destination).to be_found
      expect(destination).to have_file_contents("the source")
    end

    it "creates intermediate directories" do
      source = subject.join("..", "source")
      subject.write(source, "the source for intermediate directories")

      destination = subject.join("cp", "destination")
      subject.cp(source, destination)

      expect(destination).to be_found
      expect(destination).to have_file_contents("the source for intermediate directories")
    end

    it "overrides already existing file" do
      source = subject.join("..", "source")
      subject.write(source, "the source")

      destination = subject.join("cp")
      subject.write(destination, "the destination")
      subject.cp(source, destination)

      expect(destination).to be_found
      expect(destination).to have_file_contents("the source")
    end

    it "raises error when source cannot be found" do
      source = subject.join("missing-source")
      destination = subject.join("cp")

      expect { subject.cp(source, destination) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(source.to_s)
      end
    end
  end

  describe "#rm" do
    it "deletes path" do
      path = subject.join("delete", "file")
      subject.touch(path)
      subject.rm(path)

      expect(path).to_not be_found
    end

    it "raises error if path doesn't exist" do
      path = subject.join("delete", "file")

      expect { subject.rm(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end

    it "raises error if path is a directory" do
      path = subject.join("delete", "directory")
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
      path = subject.join("delete", "directory")
      subject.mkdir(path)
      subject.rm_rf(path)

      expect(path).to_not be_found
    end

    it "deletes a file" do
      path = subject.join("delete_directory", "file")
      subject.touch(path)
      subject.rm_rf(path)

      expect(path).to_not be_found
    end

    it "raises error if directory doesn't exist" do
      path = subject.join("delete", "directory")

      expect { subject.rm_rf(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#chmod" do
    it "sets UNIX mode" do
      path = subject.join("chmod")
      subject.touch(path)
      subject.chmod(path, mode = 0o755)

      expect(subject.mode(path)).to eq(mode)
    end

    it "raises error if path doesn't exist" do
      path = subject.join("chmod")

      expect { subject.chmod(path, 0o755) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#mode" do
    it "gets UNIX mode" do
      path = subject.join("mode")
      subject.touch(path)
      subject.chmod(path, mode = 0o755)

      expect(subject.mode(path)).to eq(mode)
    end

    it "raises error if path doesn't exist" do
      path = subject.join("mode")

      expect { subject.mode(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::IOError)
        expect(exception.cause).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to include(path.to_s)
      end
    end
  end

  describe "#exist?" do
    it "returns true for file" do
      path = subject.join("exist-file")
      subject.touch(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns true for directory" do
      path = subject.join("exist-dir")
      subject.mkdir(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns false for non-existing file" do
      path = subject.join("exist-non-existing")

      expect(subject.exist?(path)).to be(false)
    end
  end

  describe "#directory?" do
    it "returns true for directory" do
      path = subject.join("directory-dir")
      subject.mkdir(path)

      expect(subject.directory?(path)).to be(true)
    end

    it "returns false for file" do
      path = subject.join("directory-file")
      subject.touch(path)

      expect(subject.directory?(path)).to be(false)
    end

    it "returns false for non-existing path" do
      path = subject.join("directory-non-existing")

      expect(subject.directory?(path)).to be(false)
    end
  end

  describe "#executable?" do
    it "returns true when file is executable" do
      path = subject.join("executable-exec")
      subject.touch(path)
      subject.chmod(path, 0o744)

      expect(subject.executable?(path)).to be(true)
    end

    it "returns false when file isn't executable" do
      path = subject.join("executable-non-exec")
      subject.touch(path)

      expect(subject.executable?(path)).to be(false)
    end

    it "returns false when file doesn't exist" do
      path = subject.join("executable-non-existing")

      expect(subject.executable?(path)).to be(false)
    end

    it "returns true for directory" do
      path = subject.join("executable-directory")
      subject.mkdir(path)

      expect(subject.executable?(path)).to be(true)
    end
  end
end
