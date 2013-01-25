$:.unshift File.dirname(File.expand_path(__FILE__))

require 'logger'
#require 'gmb/server'
require 'gmb/config'

module GerritEventBridge
  NAME = 'GMB'

  class << self
    attr_writer :logger
    def logger(level = ::Logger::WARN)
      @logger ||= ::Logger.new(STDOUT).tap {|l| l.level = level }
    end
  end
end

GMB = GerritEventBridge
