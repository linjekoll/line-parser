describe LinearT::LinePopulator do
  use_vcr_cassette "00012110-00001075"
  
  before(:each) do
    @line = LinearT::LinePopulator.new("00012110", "00001075")
  end
  
  it "should return a list of stations" do
    @line.should have(21).stations
  end
end


# from: "00012110"
# to: "00001075"
