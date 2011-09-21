module LinearT
  class Update
    def initialize(options)
      @options = options
    end
    
    def line
      @options[:line]
    end
    
    def to_json
      @options.to_json
    end
  end
end