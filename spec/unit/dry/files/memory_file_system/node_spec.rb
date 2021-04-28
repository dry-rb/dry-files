# frozen_string_literal: true

require "dry/files/memory_file_system/node"

RSpec.describe Dry::Files::MemoryFileSystem::Node do
  subject { described_class.new(path) }
  let(:path) { "/foo" }

  describe ".root" do
    subject { described_class.root }

    it "returns a root node" do
      expect(subject).to be_kind_of(described_class)
      expect(subject.path).to eq("/")
    end
  end

  describe "#initialize" do
    it "is instance of #{described_class}" do
      expect(subject).to be_kind_of(described_class)
    end

    context "path" do
      it "accepts path argument" do
        expect(subject.path).to eq(path)
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
      expect(current.path).to eq(segment)
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
      expect(current.path).to eq(segment)
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
        expect(exception).to be_kind_of(Dry::Files::UnknownMemoryNode)
        expect(exception.message).to eq("unknown memory node `foo'")
      end
    end
  end
end
