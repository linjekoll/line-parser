# -*- encoding : utf-8 -*-
require "update"
require "base"

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
    
    def initialize(channel, id, travel_times = {}, stations = {})
      @travel_times = {}.merge(travel_times)
      @start_time   = {}
      @last_time    = {}
      @sleep_time   = {}
      @stations     = {}.merge(stations)
      @trip_ids     = [] # A list of nearby trains
      @channel      = channel # EM channel
      @id           = id # Station id
      @threshold    = 5 # Max diff
    end
    
    def update!
      url = %w{
        http://vasttrafik.se/External_Services/NextTrip.asmx/GetForecast?
        identifier=%s&
        stopId=%s
      }.join % [api_key, @id]

      download!(url).css("forecast items item").each do |stop|      
        current_time = Time.parse(stop.attr("next_trip_forecast_time")).to_i
        diff         = current_time - Time.now.to_i
        destination  = stop.at_css("destination").content
        trip_id      = stop.attr("trip_id")
        line         = stop.attr("line_id")
                
        if last_time = @last_time[trip_id] and sleep_time = @sleep_time[trip_id]
          # The tram is slower/faster that we expected
          if (current_time - last_time).abs > @threshold
            update_client = true
          end
        end
        
        # Is this the first run?
        if update_client or init?
          update_client!
        end
        
        @last_time[trip_id] = current_time
        
        # Is the tram nearby?
        # x ------------- tram --- station ---------------- next_station
        if dest = @travel_times[line] and time = dest[destination] and diff < time and diff > 0
          @trip_ids.push(trip_id)
          
          if diff > 30
            @sleep_time[trip_id] = 10
          else
            @sleep_time[trip_id] = 5
          end
          
          update_with_in(@sleep_time[trip_id])
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
    
    def update_with_in(seconds)
      if defined?(EM)
        EM.add_timer(seconds) { self.update! }
      end
    end
    
    def update_client!
      puts "DATA!"
    end
    
    def wipe(trip_id)
      @trip_ids.delete(trip_id)
      @sleep_time.delete(trip_id)
      @last_time.delete(trip_id)
    end
  end
end