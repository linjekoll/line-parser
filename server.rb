require "eventmachine"
require_relative "lib/station"

EM.run do
  worker_channel = EM::Channel.new
  worker_channel.subscribe do |params|
    puts params.red
  end
  
  
end