# -*- encoding : utf-8 -*-
require_relative "update"
require_relative "base"
require "colorize"

module LinearT
  class Station < LinearT::Base            
    #
    # @id Fixnum Station id
    # A unique identifier provided by VT. 
    # Example: 00012110 (Mölndal)
    # @name String Station name. Example; Mölndal
    #
    attr_accessor :id, :name
    
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
      @backup                 = {}
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
      
      start_timer = Time.now.to_i
      
      departures = download!(url).css("forecast items item").map do |stop|
        forecast_time = Time.parse(stop.attr("next_trip_forecast_time")).to_i
        {
          forecast_time: forecast_time,
          diff: forecast_time - Time.now.to_i,
          destination: stop.at_css("destination").content.split(" ").first.downcase,
          trip_id: stop.attr("trip_id"),
          line: stop.attr("line_id")
        }
      end
      
      # How long did the request take?
      @request_time = Time.now.to_i - start_timer
      
      return departures
    end
    
    #
    # @trip_id Trip id that should be observed
    #
    def update!(trip_id)
      @trip_id = trip_id
      # Can we update the given trip id?
      # If not; we should alert the next stop that
      # is should update the given {trip_id}
      unless departute = departures.select{ |d| d[:trip_id] == trip_id }.first
        # Is there a next station?
        # This might be the last one          
        if next_station = @backup[trip_id]
          next_station.update!(trip_id)
        else
          debug "Nope, nothing here. next_station=#{next_station}.", :red
        end
        
        wipe(trip_id)
        debug "Tram isn't here, abort abort!", :yellow; return
      end
      
      
      forecast_time = departute[:forecast_time]         # When should it be here. Time object
      destination   = departute[:destination]           # End station as a string; Example angered
      next_station  = surrounding_stations[destination] # Next station
      line          = departute[:line]                  # The current line
      diff          = departute[:diff]                  # When (in seconds) is the tram here?
      
      self.line = line
      
      if previous_forecast_time = @previous_forecast_time[trip_id] and sleep_time = @sleep_time[trip_id]
        # The given tram is slower/faster that we expected.
        # ∆ Time may not be larger then {@threshold}
        # The time it took to fetch the data {@request_time} should not be apart of the calculation.
        threshold_diff = (forecast_time - previous_forecast_time - @request_time).abs
        if threshold_diff  > @threshold
          debug "Threshold diff is now #{threshold_diff} seconds.", :red
        else
          debug "Current threshold diff is #{threshold_diff}, max is #{@threshold} seconds."
        end
      end
      
      if first_time?
        debug "First time this station is updated using trip id #{trip_id}.", :yellow
      end
      
      unless @backup[trip_id]
        @backup[trip_id] = next_station
      end
      
      # Saves the current forecast time
      @previous_forecast_time[trip_id] = forecast_time
      
      puts "NEXT STATION: #{next_station.class}" # DEBUGGER
      
      # Is the tram nearby?
      # x ------------- tram --- station ---------------- next_station
      if diff + @sleep_time[trip_id].to_i + threshold_diff.to_i >= 0          
        if diff > 30
          @sleep_time[trip_id] = 10
        else
          @sleep_time[trip_id] = 5
        end
        
        debug "Arriving at station in #{diff} seconds.", :blue
        update_in(@sleep_time[trip_id], trip_id)
        
      # Nope, it has already left the station
      # x ----------------- station --- tram ------------ next_station
      elsif @backup[trip_id]
        debug "Sending alert to next station.", :yellow
        next_station.update!(trip_id)
        wipe(trip_id)
      # This must be the end station
      # There is no 'next station'
      else
        debug "Oops, something went wrong. diff=#{diff}.", :red
        wipe(trip_id)
      end        
    end
    
    #
    # @seconds Fixnum Time in seconds to next update
    # @trip_id String Trip id that should be updated
    #
    def update_in(seconds, trip_id)
      EM.add_timer(seconds) { self.update!(trip_id) }
      debug "Next update in #{seconds} seconds.", :yellow
    end
    
    #
    # Notify client
    #
    def update_client!
      debug "update_client!", :yellow
    end
    
    #
    # Ghetto garbage collector
    # @trip_id String Clear data stored for {trip_id}
    #
    def wipe(trip_id)
      @sleep_time.delete(trip_id)
      @previous_forecast_time.delete(trip_id)
      @backup.delete(trip_id)
      debug "Whipe: #{trip_id}.", :yellow
    end
    
    #
    # @line Fixnum VT unique identifier
    # This but set before the use of;
    # Station#travel_times, #next and so on
    #
    def line=(line)
      @line = line
    end
    
    #
    # @return Boolean Is this the first time {@trip_id} is beign used?
    #
    def first_time?
      !! @previous_forecast_time[@trip_id]
    end
    
    #
    # @message String Message to be printed
    # @color Symbol Color for the given message to be printed in
    # Default color if noting is defined; green
    # Form; [trip_id][line] @message
    #
    def debug(message, color = :green)
      puts "%-42s%s" % ["[#{@name}][#{@line}][#{@trip_id}]".black, message.send(color)]
    end
    
    # Name for the next and previous station
    # @previous String Example: Brunsparken
    # def previous=(previous)
    #   @previous[@line] = previous
    # end
    
    # Name for the next and previous station
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