# -*- encoding : utf-8 -*-
require_relative "update"
require_relative "base"

module LinearT
  class Station < LinearT::Base
    # @trip_ids Array A list of trip_ids
    # Each id consists of an VT identifier
    attr_writer :trip_ids
            
    # @id Fixnum Station id
    # A unique identifier provided by VT. 
    # Example: 00012110 (Mölndal)
    attr_accessor :id
    
    # @station Hash Raw data
    # @line The current line, 4 for example
    attr_reader :station, :line
    
    def initialize(station)
      @station = station
      # @travel_times = {}.merge(options[:travel_times] || {})
      # @start_time   = {}
      # @previous_forecast_time = {}
      # @sleep_time   = {}
      # @stations     = {}.merge(options[:stations] || {})
      # @trip_ids     = [] # A list of nearby trains
      # @channel      = options[:channel] # EM channel
      # @id           = options[:id] # Station id
      # @threshold    = 5 # Max diff
    end

    
    # Getter and setter methods for;
    # @travel_times, @surrounding_station_objects, @next, @previous
    # #line must be set before this can be used
    # Take a look at the comments at the bottom of 
    # the page for more info.
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
    
    # def self_methods
    #   
    # end
    
    def get_all_trip_ids
      
    end
    
    def departures
      url = %w{
        http://vasttrafik.se/External_Services/NextTrip.asmx/GetForecast?
        identifier=%s&
        stopId=%s
      }.join % [api_key, @id]
      
      return download!(url).css("forecast items item").map do |stop|; {
          forecast_time: Time.parse(stop.attr("next_trip_forecast_time")).to_i,
          diff: forecast_time - Time.now.to_i,
          destination: stop.at_css("destination").content,
          trip_id: stop.attr("trip_id"),
          line: stop.attr("line_id")
        }
      end
    end
    
    def update!
      departures.each do |stop|      
        forecast_time = stop[:forecast_time]
        destination   = stop[:destination]
        trip_id       = stop[:trip_id]
        line          = stop[:line]
        diff          = stop[:diff]
        
        next unless @trip_ids.include?(trip_id)
                
        if previous_forecast_time = @previous_forecast_time[trip_id] and sleep_time = @sleep_time[trip_id]
          # The tram is slower/faster that we expected
          if (forecast_time - previous_forecast_time).abs > @threshold
            update_client = true
          end
        end
        
        # Is this the first run? {init?}
        update_client! if update_client or init?
        
        @previous_forecast_time[trip_id] = forecast_time
        
        # Is the tram nearby?
        # x ------------- tram --- station ---------------- next_station
        if dest = @travel_times[line] and timetable_time = dest[destination] and diff < timetable_time and diff > 0          
          if diff > 30
            @sleep_time[trip_id] = 10
          else
            @sleep_time[trip_id] = 5
          end
          update_in(@sleep_time[trip_id])
        # Nope, it has already left the station
        # x ----------------- station --- tram ------------ next_station
        elsif dest = @stations[line] and station = dest[destination]
          station.init(trip_id).update!
          wipe(trip_id)
        else
          wipe(trip_id)
        end        
      end
    end
    
    def init(trip_id)
      tap { self.trip_ids.push(trip_id); @init = true }
    end
    
    def init?
      is = @init
      @init = false
      return is
    end
    
    def update_in(seconds)
      if defined?(EM)
        puts "update_in: #{seconds}".yellow
        EM.add_timer(seconds) { self.update! }
      else
        puts "EM does not exist".red
      end
    end
    
    def update_client!
      puts "update_client!".yellow
    end
    
    def wipe(trip_id)
      @trip_ids.delete(trip_id)
      @sleep_time.delete(trip_id)
      @previous_forecast_time.delete(trip_id)
      puts "Whipe: #{trip_id}".yellow
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
        
    # @line Fixnum VT unique identifier
    # This but set before the use of;
    # #travel_times, #next and so on
    def line=(line)
      @line = line
    end
  end
end