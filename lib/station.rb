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
      @stations     = {}.merge(stations)
      @trip_ids     = [] # A list of nearby trains
      @channel      = channel # EM channel
      @id           = id # Station id
    end
    
    def update!(ingoing_trip_id = nil)
      url = %w{
        http://vasttrafik.se/External_Services/NextTrip.asmx/GetForecast?
        identifier=%s&
        stopId=%s
      }.join % [api_key, @id]

      download!(url).css("forecast items item").each do |stop|      
        diff        = Time.parse(stop.attr("next_trip_forecast_time")).to_i - Time.now.to_i
        destination = stop.at_css("destination").content
        trip_id     = stop.attr("trip_id")
        line        = stop.attr("line_id")
        
        # Is the tram nearby?
        # x ------------- tram --- station ---------------- next_station
        if dest = @travel_times[line] and time = dest[destination] and diff < time and diff > 0
          @trip_ids.push(trip_id)
          if diff > 30
            sleep_time = 10
          else
            sleep_time = 60
          end
          
          puts "DIFF: #{diff}"
          update_with_in(sleep_time)
        # Nope, it has already left the station
        # x ----------------- station --- tram ------------ next_station
        elsif @trip_ids.include?(trip_id) and dest = @stations[line] and station = dest[destination]
          station.update!(trip_id)
          @trip_ids.delete(trip_id)
        elsif @trip_ids.include?(trip_id)
          @trip_ids.delete(trip_id)
        end        
      end
    end
    
    def update_with_in(seconds)
      EM.add_timer(seconds) { self.update! }
    end
  end
end