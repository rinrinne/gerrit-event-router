$:.unshift File.dirname(File.expand_path(__FILE__))

require 'logger'
require 'yaml'
require 'uri'
require 'geb/constants'
require 'geb/config'
require 'geb/config/generic'
require 'geb/config/gerrit'
require 'geb/config/broker'
require 'geb/config/broker/amqp'
require 'geb/bridge'

module GerritEventBridge
  class << self
    attr_writer :logger
    def logger(level = ::Logger::INFO)
      @logger ||= ::Logger.new(STDOUT).tap {|l| l.level = level }
    end

    def load_config(path)
      Config.load(path)
    end

    def start(name, config)
      bridge = Bridge.new(name, config)
      bridge.start
    end
  end
end

GEB = GerritEventBridge
