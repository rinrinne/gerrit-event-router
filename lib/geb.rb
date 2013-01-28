$:.unshift File.dirname(File.expand_path(__FILE__))

require 'logger'
#require 'geb/server'
require 'geb/config'

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
