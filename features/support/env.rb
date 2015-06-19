require 'cgi'
require 'jsonpath'
require 'rspec'
require 'rubygems'
require 'ruby-jmeter'
require 'digest/md5'

RSpec.configure do |config|
  # ...
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end