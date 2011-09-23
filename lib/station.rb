# -*- encoding : utf-8 -*-
require_relative "update"
require_relative "base"

module LinearT
  class Station < LinearT::Base
    attr_reader :trip_ids
    # @channel EM.Channel Object
    # @id Station id
    # @travel_times {
    #   "4" => {
    #     "Mölndal" => 60,
    #     "Angered" => 80
    #   }
    # }    
    # @stations = {
    #   "4" => {
    #     "Mölndal" => station1,
    #     "Angered" => station2
    #   }
    # }
    
    def initialize(options)
      @travel_times = {}.merge(options[:travel_times] || {})
      @start_time   = {}
      @previous_forecast_time    = {}
      @sleep_time   = {}
      @stations     = {}.merge(options[:stations] || {})
      @trip_ids     = [] # A list of nearby trains
      @channel      = options[:channel] # EM channel
      @id           = options[:id] # Station id
      @threshold    = 5 # Max diff
    end
    
    def update!
      url = %w{
        http://vasttrafik.se/External_Services/NextTrip.asmx/GetForecast?
        identifier=%s&
        stopId=%s
      }.join % [api_key, @id]

      download!(url).css("forecast items item").each do |stop|      
        forecast_time = Time.parse(stop.attr("next_trip_forecast_time")).to_i
        diff         = forecast_time - Time.now.to_i
        destination  = stop.at_css("destination").content
        trip_id      = stop.attr("trip_id")
        line         = stop.attr("line_id")
                
        if last_time = @previous_forecast_time[trip_id] and sleep_time = @sleep_time[trip_id]
          # The tram is slower/faster that we expected
          if (forecast_time - last_time).abs > @threshold
            update_client = true
          end
        end
        
        # Is this the first run? {init?}
        if update_client or init?
          update_client!
        end
        
        @previous_forecast_time[trip_id] = forecast_time
        
        # Is the tram nearby?
        # x ------------- tram --- station ---------------- next_station
        if dest = @travel_times[line] and timetable_time = dest[destination] and diff < timetable_time and diff > 0
          @trip_ids.push(trip_id)
          
          if diff > 30
            @sleep_time[trip_id] = 10
          else
            @sleep_time[trip_id] = 5
          end
          
          update_in(@sleep_time[trip_id])
        # Nope, it has already left the station
        # x ----------------- station --- tram ------------ next_station
        elsif @trip_ids.include?(trip_id) and dest = @stations[line] and station = dest[destination]
          station.init.update!
          wipe(trip_id)
        elsif @trip_ids.include?(trip_id)
          wipe(trip_id)
        end        
      end
    end
    
    def init
      tap { @init = true }
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
  end
end