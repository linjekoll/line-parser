require "rspec"
require "webmock/rspec"
require "vcr"
require "json"

require_relative "../lib/station"
require_relative "../lib/update"
require_relative "../lib/line_populator"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.mock_with :rspec
  config.extend VCR::RSpec::Macros
end

VCR.config do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.stub_with :webmock
  c.default_cassette_options = {
    record: :new_episodes
  }
  c.allow_http_connections_when_no_cassette = false
end