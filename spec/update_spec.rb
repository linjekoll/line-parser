describe LinearT::Update do
  let(:hash) do
    {
      random: 1,
      line: 2
    }
  end
  
  before(:each) do
    @update = LinearT::Update.new(hash)
  end
  
  it "should be able to convert to json" do
    @update.to_json.should eq(hash.to_json)
  end
  
  it "should have a line" do
    @update.line.should eq(hash[:line])
  end
end