require "eventmachine"
require "time"
require_relative "lib/line_populator"
require_relative "lib/station"

EM.run do
  worker_channel = EM::Channel.new
  worker_channel.subscribe do |params|
    puts "Params: #{params}".yellow
  end
  
  line_populator = LinearT::LinePopulator.new("00012110", "00001075")
  
  stations = line_populator.stations
  
  new_stations = []
  stations.map! do |station|
    LinearT::Station.new(station)
  end
  
  stations.each_with_index do |s, index|
    station = s.station
        
    previous = station[:before] || {}
    after = station[:after] || {}
    
    s.line = "4"
    
    s.travel_times = {
      line_populator.start => previous[:time],
      line_populator.stop => after[:time]
    }
    
    s.surrounding_stations = {
      line_populator.start => stations[index - 1],
      line_populator.stop => stations[index + 1]
    }
        
    s.id = station[:id]
    new_stations << s
  end
  
  station = stations[4]
  w = station.departures.reject do |dep|
    not dep[:line] == "4" 
  end
  
  trip_id = w.first[:trip_id]
  
  station.update!(trip_id)
  
end

# ,
# stations: {
#   station[:line] => {
#     before[:name] => stations[index - 1],
#     after[:name] => stations[index + 1]
#   }
# },