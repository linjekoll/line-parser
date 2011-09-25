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
  stations.map do |station|
    s = LinearT::Station.new
    
    s.line = "4"
    
    previous = station[:before] || {}
    nect = station[:after] || {}
    
    s.previous = before[:name]
    s.next = after[:name]
    
    s.travel_times = {
      s.before => before[:time],
      s.after => after[:time]
    }
    
    s.id = station[:id]    
    
    s.surrounding_stations = {
      station.before => stations[index - 1],
      station.after => stations[index + 1]
    }
    
    # index++
    index = index + 1    
  end
end

# ,
# stations: {
#   station[:line] => {
#     before[:name] => stations[index - 1],
#     after[:name] => stations[index + 1]
#   }
# },