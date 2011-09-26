require "eventmachine"
require "time"

require_relative "lib/line_populator"
require_relative "lib/station"
require_relative "lib/fetch"

EM.run do
  # Our cache
  cached_stations = {}
  
  # 00012110 => 00001075 : Mölndal to Angered : 4
  # 00001075 => 00004100 : Angered to Kungssten : 9
  # 00001075 => 00002530 : Angered to Frölunda : 8
  # 00003940 => 00005170 : Komettorget to Opaltorget : 7
  # 00007280 => 00006835 : Varmfrontsgatan to Torp : 5
  # 00004210 => 00004760 : Kålltorp to Marklandsgatan : 3
  [{
    from: "00012110", 
    to: "00001075", 
    id: "4"
  }, {
    from: "00001075",
    to: "00004100",
    id: "9"
  }, {
    from: "00001075",
    to: "00002530",
    id: "8"
  }, {
    from: "00003940",
    to: "00005170",
    id: "7"
  }, {
    from: "00007280",
    to: "00006835",
    id: "5"
  }, {
    from: "00004210",
    to: "00004760",
    id: "3"
  }].each do |line|
    lp = LinearT::LinePopulator.new(line[:from], line[:to], line[:id])
    cached_stations = LinearT::Fetch.new(cached_stations, lp).execute!
  end
    
  # Trip id container
  started   = []
  
  cached_stations.keys.each do |id|
    station = cached_stations[id]
    # Fetching all departures for the given station
    departure = station.departures.reject do |departure|
      departure[:diff] <= 0 # Removing departures with negative or zero departure time
    end.sort_by do |departure|
       departure[:diff] # Selecting the station with the earliest departure time
    end.first    
    
    # We don't want to start anything if the given {trip_id} has been used
    if departure and not started.include?(departure[:trip_id])
      started << departure[:trip_id]
      puts "Starting #{departure[:trip_id]}"
      EM.defer { station.update!(departure[:trip_id], true) }
    end
  end
end