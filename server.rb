require "eventmachine"
require "time"
require_relative "lib/line_populator"
require_relative "lib/station"

EM.run do
  worker_channel = EM::Channel.new
  worker_channel.subscribe do |params|
    puts "Params: #{params}".yellow
  end
  
  index = 0
  stations = LinearT::LinePopulator.new("00012110", "00001075").stations
  new_stations = []
  stations.map! do |station|
    LinearT::Station.new(station)
  end
  
  stations.each_with_index do |s, index|
    station = s.station
    s.line = "4"
    
    previous = station[:before] || {}
    after = station[:after] || {}
    
    s.previous = previous[:name]
    s.next = after[:name]
    
    s.travel_times = {
      previous: previous[:time],
      next: after[:time]
    }
    
    s.surrounding_stations = {
      previous: stations[index - 1],
      next: stations[index + 1]
    }
    
    s.id = station[:id]
    new_stations << s
  end
end

# ,
# stations: {
#   station[:line] => {
#     before[:name] => stations[index - 1],
#     after[:name] => stations[index + 1]
#   }
# },