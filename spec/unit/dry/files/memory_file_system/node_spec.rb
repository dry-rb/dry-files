# frozen_string_literal: true

require "dry/files/memory_file_system/node"

RSpec.describe Dry::Files::MemoryFileSystem::Node do
  subject { described_class.new(path) }
  let(:path) { "/usr" }
  let(:newline) { $INPUT_RECORD_SEPARATOR }

  describe ".root" do
    subject { described_class.root }

    it "returns a root node" do
      expect(subject).to be_kind_of(described_class)
      expect(subject.segment).to eq("/")
    end
  end

  describe "#initialize" do
    it "is instance of #{described_class}" do
      expect(subject).to be_kind_of(described_class)
    end

    context "path" do
      it "accepts path argument" do
        expect(subject.segment).to eq(path)
      end
    end

    context "mode" do
      it "defaults to directory mode" do
        expected = 0b111101100 # 0644
        expect(subject.mode).to eq(expected)
      end

      it "accepts optional mode argument (hex)" do
        mode = 0b100000000 # 0400
        subject = described_class.new(path, mode)

        expect(subject.mode).to eq(mode)
      end

      it "accepts optional mode argument (oct)" do
        mode = 0o400
        subject = described_class.new(path, mode)

        expected = 0b100000000 # 0400
        expect(subject.mode).to eq(expected)
      end
    end
  end

  describe "#get" do
    before { subject.set(segment) }
    let(:segment) { "tmp" }

    it "returns child node" do
      current = subject.get(segment)
      expect(current).to be_kind_of(described_class)
      expect(current.segment).to eq(segment)
    end

    it "returns nil when given segment doesn't match any children" do
      expect(subject.get("foo")).to be(nil)
    end
  end

  describe "#set" do
    let(:segment) { "tmp" }

    it "sets child node" do
      subject.set(segment)

      current = subject.get(segment)
      expect(current).to be_kind_of(described_class)
      expect(current.segment).to eq(segment)
    end

    it "doesn't override existing node" do
      subject.set(segment)
      current = subject.get(segment)
      subject.set(segment) # override attempt

      expect(subject.get(segment).object_id).to eq(current.object_id)
    end
  end

  describe "#unset" do
    before { subject.set(segment) }
    let(:segment) { "tmp" }

    it "removes child" do
      subject.unset(segment)
      expect(subject.get(segment)).to be(nil)
    end

    it "raises error if trying to remove unexisting child" do
      expect { subject.unset("foo") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::UnknownMemoryNodeError)
        expect(exception.message).to eq("unknown memory node `foo'")
      end
    end
  end

  describe "#directory?" do
    it "is true by default" do
      expect(subject.directory?).to be(true)
    end

    it "is false when node has a content" do
      subject.write("foo")
      expect(subject.directory?).to be(false)
    end
  end

  describe "#file?" do
    it "is false by default" do
      expect(subject.file?).to be(false)
    end

    it "is true when node has a content" do
      subject.write("foo")
      expect(subject.file?).to be(true)
    end
  end

  describe "#read" do
    it "reads file content" do
      subject.write("foo")
      expect(subject.read).to eq("foo")
    end

    it "raises error when not file" do
      expect { subject.read }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::NotMemoryFileError)
        expect(exception.message).to eq("not a memory file `#{path}'")
      end
    end
  end

  describe "#readlines" do
    it "reads file content" do
      subject.write("foo")
      expect(subject.readlines).to eq(["foo"])

      subject.write("foo#{newline}bar")
      expect(subject.readlines).to eq(%w[foo bar])
    end

    it "raises error when not file" do
      expect { subject.readlines }.to raise_error do |exception|
        expect(exception).to be_kind_of(Dry::Files::NotMemoryFileError)
        expect(exception.message).to eq("not a memory file `#{path}'")
      end
    end
  end

  describe "#write" do
    it "sets file content" do
      subject.write("foo")
      expect(subject.read).to eq("foo")

      subject.write("foo#{newline}bar")
      expect(subject.read).to eq("foo#{newline}bar")
    end

    it "sets file mode" do
      subject.write("foo")
      expected = 0b110100100 # 0644

      expect(subject.mode).to eq(expected)
    end
  end

  describe "#chmod=" do
    it "sets file mode (base 2)" do
      expected = 0b001000000 # 0100

      subject.chmod = expected
      expect(subject.mode).to eq(expected)
    end

    it "sets file mode (base 8)" do
      expected = 0b001000000 # 0100

      subject.chmod = 0o100
      expect(subject.mode).to eq(expected)
    end

    it "sets file mode (base 10)" do
      expected = 0b001000000 # 0100

      subject.chmod = 64
      expect(subject.mode).to eq(expected)
    end

    it "sets file mode (base 16)" do
      expected = 0b111101101 # 0755

      subject.chmod = 0x1ed
      expect(subject.mode).to eq(expected)
    end
  end

  describe "#executable?" do
    it "is true by default" do
      # Default mode for node is directory.
      # By default, UNIX directories are executable.
      expect(subject.executable?).to be(true)
    end

    it "is false when file" do
      subject.write("foo")
      expect(subject.executable?).to be(false)
    end

    it "is true when executable for user" do
      subject.chmod = 0o744
      expect(subject.executable?).to be(true)
    end

    it "is false when not executable for user" do
      subject.chmod = 0o474 # executable for group
      expect(subject.executable?).to be(false)

      subject.chmod = 0o447 # executable for others
      expect(subject.executable?).to be(false)
    end
  end
end
