module LinearT
  class Base
    def api_key
      "3e04f738-a43f-4670-b2ec-abd775867ac5"
    end
    
    def download!(url)
      Nokogiri::XML(lambda {
        data =  RestClient.get(url)
        data = data.match(%r{<string xmlns="http://vasttrafik.se/">(.+)</string>}).to_a[1].to_s
        data.gsub(%r{&lt;}, "<").gsub(%r{&gt;}, ">")
      }.call)
    end
  end
end
