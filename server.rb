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
    before = station[:before] || {}
    after = station[:after] || {}
    
    hash = {
      travel_times: {
        station[:line] => {
          before[:name] => before[:time],
          after[:name] => after[:time]
        }
      },
      stations: {
        station[:line] => {
          before[:name] => stations[index - 1],
          after[:name] => stations[index + 1]
        }
      },
      id: station[:id]
    }
    
    puts "Running: #{station[:id]}"
    EM.defer { LinearT::Station.new(hash).update! }
    
    # index++
    index = index + 1
  end
end