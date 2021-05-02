# frozen_string_literal: true

RSpec.describe "Dry::Files::VERSION" do
  it "exposes version" do
    expect(Dry::Files::VERSION).to eq("0.1.0")
  end
end
