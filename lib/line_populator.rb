require "nokogiri"
require "rest-client"
require "yaml"
require "colorize"
module LinearT
  class LinePopulator
    def initialize(from, to)
      @from = from
      @to = to
      @api_key = "3e04f738-a43f-4670-b2ec-abd775867ac5"
    end
    
    def stations
      item = content.at_css("items item")
      @stops = item.css("between_stops item").map do |stop|        
        {
          name: stop.at_css("stop_name").content,
          stop_time: Time.parse(stop.attr("stop_time")),
          id: stop.attr("stop_id"),
          line: stop.attr("line_id")
        }
      end
      
      @stops
    end
    
    private
      def content
        @_content ||= Nokogiri::XML(fetch)
      end
      
      def fetch
        options = [@api_key, @from, @to, URI.escape("2011-09-15 12:00"), 1,1,0,1]
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
        
        data =  RestClient.get(url)
        data = data.match(%r{<string xmlns="http://vasttrafik.se/">(.+)</string>}).to_a[1].to_s
        data.gsub(%r{&lt;}, "<").gsub(%r{&gt;}, ">")
      end
  end
end