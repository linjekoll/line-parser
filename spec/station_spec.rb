# -*- encoding : utf-8 -*-
describe LinearT::Station do
  describe "simple" do
    use_vcr_cassette "00003980"
    before(:each) do
      @travel_times = {
        "4" => {
          "Mölndal" => 360,
          "Angered" => 250
        }
      }
      @station = LinearT::Station.new(nil, "00003980", @travel_times)
    end
    
    it "should add a trip id" do
      Timecop.travel(Time.parse("21 Sep 2011 16:10:37 GMT")) do
        @station.update!(nil)
        @station.trip_ids.should include("30810")
      end
    end
    
    it "should NOT add a trip id" do
      Timecop.travel(Time.parse("22 Sep 2011 16:10:37 GMT")) do
        @station.update!(nil)
        @station.trip_ids.should_not include("30810")
      end
    end
  end
end