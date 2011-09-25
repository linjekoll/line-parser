# -*- encoding : utf-8 -*-
require_relative "update"
require_relative "base"

module LinearT
  class Station < LinearT::Base            
    #
    # @id Fixnum Station id
    # A unique identifier provided by VT. 
    # Example: 00012110 (Mölndal)
    #
    attr_accessor :id
    
    #
    # @station Hash Raw data
    # @line The current line, 4 for example
    #
    attr_reader :station, :line
    
    #
    # @station A raw Hash from the LinePopulation class
    #
    def initialize(station)
      @station                = station
      @threshold              = 5
      @previous_forecast_time = {}
      @sleep_time             = {}
    end

    #
    # Getter and setter methods for;
    # @travel_times, @surrounding_station_objects, @next, @previous
    # Station#line must be set before this can be used
    # Take a look at the comments at the bottom of 
    # the page for more info.
    #
    [:travel_times, :surrounding_stations, :next, :previous].each do |method|
      define_method(method) do
        instance_variable_get("@#{method}")[@line] || {}
      end
      
      define_method("#{method}=") do |value|
        var = instance_variable_get("@#{method}")
        instance_variable_set("@#{method}", {}) unless var
        instance_variable_get("@#{method}")[@line] = value
      end
    end
    
    #
    # @return A list of departures
    # Each departure on the following form
    # {
    #   forecast_time: 2011-09-25 22:18:51 +0200
    #   diff: 41
    #   destination: "angered"
    #   trip_id: 123123
    #   line: "4"
    # }
    #
    # forecast_time: Time When should it be here.
    # diff: Fixnum When (in seconds) is the tram here?
    # destination: End station as a string.
    # line: The current line.
    # 
    def departures
      url = %w{
        http://vasttrafik.se/External_Services/NextTrip.asmx/GetForecast?
        identifier=%s&
        stopId=%s
      }.join % [api_key, @id]
      
      return download!(url).css("forecast items item").map do |stop|
        forecast_time = Time.parse(stop.attr("next_trip_forecast_time")).to_i
        {
          forecast_time: forecast_time,
          diff: forecast_time - Time.now.to_i,
          destination: stop.at_css("destination").content.split(" ").first.downcase,
          trip_id: stop.attr("trip_id"),
          line: stop.attr("line_id")
        }
      end
    end
    
    #
    # @trip_id Trip id that should be observed
    #
    def update!(trip_id)
      # Can we update the given trip id?
      # If not; we should alert the next stop that
      # is should update the given {trip_id}
      unless departute = departures.select{ |d| d[:trip_id] == trip_id }.first
        # TODO: Alert the next stop that is should update it self.
        # surrounding_stations[departures[:destination]].init.update!(trip_id)
        puts "Trip isn't here, abort abort!".yellow; return
      end
      
      forecast_time = departute[:forecast_time] # When should it be here. Time object
      destination   = departute[:destination]   # End station as a string; Example angered
      line          = departute[:line]          # The current line
      diff          = departute[:diff]          # When (in seconds) is the tram here?
      
      self.line = line
      
      if previous_forecast_time = @previous_forecast_time[trip_id] and sleep_time = @sleep_time[trip_id]
        # The given tram is slower/faster that we expected.
        # ∆ Time may not be larger then {@threshold} 
        threshold_diff = (forecast_time - previous_forecast_time).abs
        if threshold_diff  > @threshold
          update_client = true
        else
          puts "Current threshold diff is #{threshold_diff}, max is #{@threshold}.".green
        end
      end
      
      # Is this the first run? {init?}
      if update_client or init?
        # TODO: Update client; update_client!
        puts "Train as left the station"
      end
      
      # Saves the current forecast time
      @previous_forecast_time[trip_id] = forecast_time
      
      # Is the tram nearby?
      # x ------------- tram --- station ---------------- next_station
      if diff > 0          
        if diff > 30
          @sleep_time[trip_id] = 10
        else
          @sleep_time[trip_id] = 5
        end
        puts "Current diff is: #{diff}"
        update_in(@sleep_time[trip_id], trip_id)
        
      # Nope, it has already left the station
      # x ----------------- station --- tram ------------ next_station
      elsif next_station = surrounding_stations[destination]
        next_station.init(trip_id).update!
        wipe(trip_id)
      
      # This must be the end station
      # There is no 'next station'
      else
        wipe(trip_id)
      end        
    end
    
    #
    # @return Station
    #
    def init
      tap { @init = true }
    end
    
    #
    # @return Boolean Has Station#init been called?
    #
    def init?
      is = @init
      @init = false
      return is
    end
    
    #
    # @seconds Fixnum Time in seconds to next update
    # @trip_id String Trip id that should be updated
    #
    def update_in(seconds, trip_id)
      EM.add_timer(seconds) { self.update!(trip_id) }
      puts "update_in: #{seconds}".yellow
    end
    
    #
    # Notify client
    #
    def update_client!
      puts "update_client!".yellow
    end
    
    #
    # Ghetto garbage collector
    # @trip_id String Clear data stored for {trip_id}
    #
    def wipe(trip_id)
      @sleep_time.delete(trip_id)
      @previous_forecast_time.delete(trip_id)
      puts "Whipe: #{trip_id}".yellow
    end
    
    #
    # @line Fixnum VT unique identifier
    # This but set before the use of;
    # Station#travel_times, #next and so on
    #
    def line=(line)
      @line = line
    end
    
    # Name of the next and previous station
    # @previous String Example: Brunsparken
    # def previous=(previous)
    #   @previous[@line] = previous
    # end
    
    # Name of the next and previous station
    # @next String Example: Brunsparken
    # def next=(next_station)
    #   @next[@line] = next_station
    # end
    
    # @travel_times Hash Time to next station
    # Example: {
    #  previous: 10,
    #  next: 10
    # }
    # It takes 10 seconds to travel 
    # from this station to next one.  
    # def travel_times=(travel_times)
    #   @travel_times[@line] = travel_times
    # end
        
    # @surrounding_station_objects Hash A hash of stations
    # Example: {
    #  previous: LinearT::Station.new
    #  next: LinearT::Station.new
    # }
    # def surrounding_stations=(surrounding_stations)
    #   @surrounding_stations[@line] = surrounding_stations
    # end
  end
end