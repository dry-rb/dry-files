# frozen_string_literal: true

RSpec.describe Dry::Files::Error do
  it "inherits from StandardError" do
    expect(subject).to be_kind_of(described_class)
    expect(subject).to be_kind_of(StandardError)
  end
end

RSpec.describe Dry::Files::IOError do
  subject { described_class.new(cause) }
  let(:cause) { Errno::ENOENT.new(Dir.pwd) }

  it "inherits from Dry::Files::Error" do
    expect(subject).to be_kind_of(Dry::Files::Error)
  end

  it "wraps low level I/O error" do
    expect(subject.message).to eq(cause.message)
    expect(subject.cause).to eq(cause)
  end
end

RSpec.describe Dry::Files::MissingTargetError do
  subject { described_class.new(target, path) }
  let(:target) { /rspec/i }
  let(:path) { Pathname.new(__FILE__) }

  it "inherits from Dry::Files::Error" do
    expect(subject).to be_kind_of(Dry::Files::Error)
  end

  it "exposes error information" do
    expect(subject.message).to eq("cannot find `#{target}' in `#{path}'")
    expect(subject.target).to eq(target)
    expect(subject.path).to eq(path)
  end
end
