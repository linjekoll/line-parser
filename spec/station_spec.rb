describe LinearT::Station do
  describe "simple" do
    use_vcr_cassette "00003980"
    before(:each) do
      @station = LinearT::Station.new(nil, "00003980")
    end
    
    it "should do something" do
      Timecop.travel(Time.parse("21 Sep 2011 16:10:37 GMT")) do
        @station.update!(nil)
      end
    end
  end
end