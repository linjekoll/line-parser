require "eventmachine"
require "time"
require_relative "lib/line_populator"

EM.run do
  worker_channel = EM::Channel.new
  worker_channel.subscribe do |params|
    puts "Params: #{params}".yellow
  end
  
  LinearT::LinePopulator.new("00012110", "00001075").stations.each do |station|
    puts "STOP: #{station}"
  end
end