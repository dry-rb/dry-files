# frozen_string_literal: true

require "dry/files/path"

RSpec.describe Dry::Files::Path do
  describe ".call" do
    let(:unix_file_separator) { "/" }
    let(:windows_file_separator) { "\\" }

    context "when string" do
      it "recombines given path with system file separator" do
        tokens = %w[path to file]
        expected = tokens.join(::File::SEPARATOR)

        expect(described_class.call(tokens.join(unix_file_separator))).to eq(expected)
        expect(described_class.call(tokens.join(windows_file_separator))).to eq(expected)
      end
    end

    context "when array" do
      it "recombines given path with system file separator" do
        tokens = %w[path to file]
        expected = tokens.join(::File::SEPARATOR)

        expect(described_class.call(tokens)).to eq(expected)
      end
    end

    context "when splat arguments" do
      it "recombines given path with system file separator" do
        tokens = ["path", %w[to file]]
        expected = tokens.flatten.join(::File::SEPARATOR)

        expect(described_class.call(*tokens)).to eq(expected)
      end
    end
  end

  describe ".[]" do
    it "is a .call alias" do
      path = "path/to/file"

      expect(described_class[path]).to eq(described_class.call(path))
    end
  end

  describe ".split" do
    it "splits path according to the current OS directory separator" do
      expected = %w[path to file]
      path = expected.join(::File::SEPARATOR)

      expect(described_class.split(path)).to eq(expected)
    end

    it "returns empty token when path equals to current OS directory separator" do
      path = ::File::SEPARATOR

      expect(described_class.split(path)).to eq("")
    end
  end

  describe ".absolute?" do
    it "returns true when path starts with current OS directory separator" do
      separator = ::File::SEPARATOR

      expect(described_class.absolute?(separator)).to be(true)
      expect(described_class.absolute?("#{separator}foo")).to be(true)
    end

    it "returns false when path starts with any other token" do
      expect(described_class.absolute?("foo")).to be(false)
    end
  end

  describe ".dirname" do
    it "returns directory name for given path" do
      path = ::File::SEPARATOR
      expect(described_class.dirname(path)).to eq(::File::SEPARATOR)

      path = "#{::File::SEPARATOR}foo"
      expect(described_class.dirname(path)).to eq(::File::SEPARATOR)

      path = "#{::File::SEPARATOR}#{%w[foo bar].join(::File::SEPARATOR)}"
      expect(described_class.dirname(path)).to eq("#{::File::SEPARATOR}foo")
    end
  end
end
