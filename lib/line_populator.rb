require "nokogiri"
require "rest-client"
require "yaml"
require "colorize"
require_relative "base"

module LinearT
  class LinePopulator < LinearT::Base
    def initialize(from, to)
      @from = from
      @to = to
    end
    
    def stations
      return @stops if @stops
       item = content.at_css("items item")    
       line = item.at_css("item").attr("line").split(",")[0]
       @stops = item.css("between_stops item").map do |stop|
         {
           name: stop.at_css("stop_name").content,
           stop_time: Time.parse(stop.attr("stop_time")),
           id: stop.attr("stop_id"),
           line: line
         }
       end

       @stops.each_with_index do |stop, index|
         if before = @stops[index - 1] and index > 0
           result = stop[:stop_time].to_i - before[:stop_time].to_i
           @stops[index].merge!({
             before[:name] => result 
           })
         end

         if after = @stops[index + 1]
           result = after[:stop_time].to_i - stop[:stop_time].to_i
           @stops[index].merge!({
             after[:name] => result 
           })
         end
       end

       @stops    
     end
    
    private      
      def content
        options = [api_key, @from, @to, URI.escape("2011-09-15 12:00"), 1,1,0,1]
        url = %w{
          http://vasttrafik.se/External_Services/TravelPlanner.asmx/GetRoute?
          identifier=%s&
          fromId=%s&
          toId=%s&
          dateTimeTravel=%s&
          whenId=%s&
          priorityId=%s&
          numberOfResultBefore=%s&
          numberOfResulsAfter=%s
        }.join % options
        
        download!(url)        
      end
  end
end