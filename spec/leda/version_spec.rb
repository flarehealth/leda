require 'spec_helper'

describe Leda, "::VERSION" do
  it "exists" do
    expect { Leda::VERSION }.not_to raise_error
  end

  it "has 3 or 4 dot separated parts" do
    expect(Leda::VERSION.split('.').size).to be_between(3, 4)
  end
end
