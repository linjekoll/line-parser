module LinearT
  class Fetch
    #
    # @cache Hash The old cache
    # A list for stations for
    #
    def initialize(cache, lp)
      @cache          = cache
      @stations       = lp.stations
      @line_populator = lp
    end
    
    #
    # @return Hash {
    # id: LinearT::Station
    # }
    #
    def execute!
      @stations = @stations.map do |station|
        LinearT::Station.new(station)
      end

      @stations.each_with_index do |s, index|
        station = s.station

        before = station[:before] || {}
        after = station[:after] || {}

        # Current line
        s.line = @line_populator.line

        # {before[:time]} <= Time in seconds to next station
        s.travel_times = {
          @line_populator.start => before[:time],
          @line_populator.stop => after[:time]
        }

        # Is there a cached version?
        if s1 = @stations[index - 1] and start = @cache[s1.id]
          puts "Start station #{s1.name} found.".green
        else
          start = s1
        end

        if s2 = @stations[index + 1] and stop = @cache[s2.id]
          puts "Stop station #{s2.name} found.".green
        else
          stop = s2
        end

        # {start}, {stop} LinearT::Station
        s.surrounding_stations = {
          @line_populator.start => start,
          @line_populator.stop => stop
        }

        # Station name
        s.name = station[:name]

        # Station id
        s.id = station[:id]

        # Cache station
        @cache[s.id] = s
      end
      
      return @cache
    end
  end
end