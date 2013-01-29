$:.unshift File.dirname(File.expand_path(__FILE__))

require 'logger'
require 'yaml'
require 'uri'
require 'geb/config'
require 'geb/config/gerrit'
require 'geb/config/broker'
require 'geb/bridge'

module GerritEventBridge
  NAME = 'GEB'

  class << self
    attr_writer :logger
    def logger(level = ::Logger::WARN)
      @logger ||= ::Logger.new(STDOUT).tap {|l| l.level = level }
    end
  end
end

GEB = GerritEventBridge
