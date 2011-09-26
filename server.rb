require "eventmachine"
require "time"
require_relative "lib/line_populator"
require_relative "lib/station"

EM.run do
  line_populator = LinearT::LinePopulator.new("00012110", "00001075", "4")
  stations       = line_populator.stations
  hash_stations  = {}
  
  stations.map! do |station|
    LinearT::Station.new(station)
  end
  
  stations.each_with_index do |s, index|
    station = s.station
    
    before = station[:before] || {}
    after = station[:after] || {}
    
    # Current line
    s.line = line_populator.line
    
    # {before[:time]} <= Time in seconds to next station
    s.travel_times = {
      line_populator.start => before[:time],
      line_populator.stop => after[:time]
    }
    
    # Is there a cached version?
    if s1 = stations[index - 1] and start = hash_stations[s1.id]
      puts "Start station #{s1.name} found.".green
    else
      start = s1
    end
    
    if s2 = stations[index + 1] and stop = hash_stations[s2.id]
      puts "Stop station #{s2.name} found.".green
    else
      stop = s2
    end
    
    # {start}, {stop} LinearT::Station
    s.surrounding_stations = {
      line_populator.start => start
      line_populator.stop => stop
    }
    
    # Station name
    s.name = station[:name]
    
    # Station id
    s.id = station[:id]
    
    # Cache station
    hash_stations[s.id] = s
  end

  departure = nil
  station   = nil
  started   = []
  
  hash_stations.keys.each do |id|
    station = hash_stations[id]
    
    # Fetching all departures for the given station
    departure = station.departures.reject do |departure|
      departure[:diff] <= 0 # Removing departures with negative or zero departure time
    end.sort_by do |departure|
       departure[:diff] # Selecting the station with the earliest departure time
    end.first    
    
    # We don't want to start anything if the given {trip_id} has been used
    if not departure.nil? and not started.include?(departure[:trip_id])
      started << departure[:trip_id]
      EM.defer { station.update!(departure[:trip_id], true) }
    end
  end  
end