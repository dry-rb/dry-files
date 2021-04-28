# frozen_string_literal: true

RSpec.describe Dry::Files::Adapter do
  describe ".call" do
    let(:subject) { described_class.call(memory: memory) }

    context "memory: true" do
      let(:memory) { true }

      it "returns memory file system adapter" do
        expect(subject).to be_kind_of(Dry::Files::MemoryFileSystem)
      end
    end

    context "memory: false" do
      let(:memory) { false }

      it "returns real file system adapter" do
        expect(subject).to be_kind_of(Dry::Files::FileSystem)
      end
    end
  end
end
