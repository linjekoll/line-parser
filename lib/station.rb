module LinearT
  class Station
    def initialize(channel)
      @travel_times = {}
      @start_time   = {}
      @stations     = {}
      @trip_id      = []
      @channel      = channel
    end
    
    def update!(trip_id)
      
    end
  end
end