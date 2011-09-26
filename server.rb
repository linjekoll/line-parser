require "eventmachine"
require "time"
require_relative "lib/line_populator"
require_relative "lib/station"

EM.run do
  line_populator = LinearT::LinePopulator.new("00012110", "00001075")
  
  stations = line_populator.stations
  
  new_stations = []
  stations.map! do |station|
    LinearT::Station.new(station)
  end
  
  stations.each_with_index do |s, index|
    station = s.station
  
    before = station[:before] || {}
    after = station[:after] || {}
    
    s.line = "4"
    
    s.travel_times = {
      line_populator.start => before[:time],
      line_populator.stop => after[:time]
    }
    
    s.surrounding_stations = {
      line_populator.start => stations[index - 1],
      line_populator.stop => stations[index + 1]
    }
    
    s.name = station[:name]
    
    s.id = station[:id]
    new_stations << s
  end
  
  departure = nil
  station = nil
  stations.each do |station|
    departure = station.departures.reject do |dep|
      not dep[:line] == "4" 
    end.first
    
    unless departure.nil?
      station.update!(departure[:trip_id]); break
    end
  end  
end