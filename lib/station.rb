require "update"
require "base"

module LinearT
  class Station < LinearT::Base
    # @channel EM.Channel Object
    # @id Station id
    # @
    def initialize(channel, id)
      @travel_times = {}
      @start_time   = {}
      @stations     = {}
      @trip_id      = [] # A list of nearby trains
      @channel      = channel # EM channel
      @id           = id # Station id
    end
    
    def update!(trip_id)
      url = %w{
        http://vasttrafik.se/External_Services/NextTrip.asmx/GetForecast?
        identifier=%s&
        stopId=%s
      }.join % [api_key, @id]
      
      download!(url).css("forecast items item").each do |stop|
        puts "It's %s seconds left for line %s.".green % [Time.parse(stop.attr("next_trip_forecast_time")).to_i - Time.now.to_i, stop.attr("line_id")]
      end
    end
  end
end