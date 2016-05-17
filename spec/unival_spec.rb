require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Unival" do
  it "has the App constant" do
    expect(Unival::App).to be_kind_of(Module)
  end
end
