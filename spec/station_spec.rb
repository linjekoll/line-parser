# -*- encoding : utf-8 -*-
describe LinearT::Station do
  use_vcr_cassette "00003980"
  before(:each) do
    @travel_times = {
      "4" => {
        "Mölndal" => 360,
        "Angered" => 250
      }
    }
    
    station1 = mock(Object.new)
    station2 = mock(Object.new)
    
    @stations = {
      "4" => {
        "Mölndal" => station1,
        "Angered" => station2
      }
    }
  end
  
  describe "trip id" do
    before(:each) do
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
    
    it "should remove trip id if trap has passed the current station" do
      Timecop.travel(Time.parse("21 Sep 2011 16:10:37 GMT")) do
        @station.update!(nil)
      end
      
      Timecop.travel(Time.parse("21 Sep 2011 17:30:37 GMT")) do
        @station.update!(nil)
        @station.trip_ids.should_not include("30810")
      end
    end
  end
  
  describe "station" do
    before(:each) do
      @station = LinearT::Station.new(nil, "00003980", @travel_times, @stations)
    end
    
    it "should notify the next station" do
      Timecop.travel(Time.parse("21 Sep 2011 16:10:37 GMT")) do
        @station.update!(nil)
      end
      
      @stations["4"]["Mölndal"].should_receive(:update!)
      
      Timecop.travel(Time.parse("21 Sep 2011 17:10:37 GMT")) do
        @station.update!(nil)
      end
    end
  end
  
  describe "time" do
    before(:each) do
      @station = LinearT::Station.new(nil, "00003980", @travel_times)
    end
    
    it "should be able to calculate update time, > 30" do
      Timecop.travel(Time.parse("21 Sep 2011 16:10:37 GMT")) do
        # Next update in 10 sec
        @station.should_receive(:update_with_in).with(10)
        @station.update!(nil)
      end
    end
    
    it "should be able to calculate update time, < 30" do
      Timecop.travel(Time.parse("21 Sep 2011 16:12:37 GMT")) do
        # Next update in 10 sec
        @station.should_receive(:update_with_in).with(5)
        @station.update!(nil)
      end
    end
    
  end
end