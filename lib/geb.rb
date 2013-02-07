# -*- coding: utf-8 -*-
$:.unshift File.dirname(File.expand_path(__FILE__))

require 'logger'
require 'yaml'
require 'uri'
require 'geb/constants'
require 'geb/config'
require 'geb/bridge'
require 'geb/gerrit'
require 'geb/broker'
require 'geb/broker/amqp'

module GerritEventBridge
  class << self
    attr_writer :logger
    def logger(level = ::Logger::INFO)
      @logger ||= ::Logger.new(STDOUT).tap {|l| l.level = level }
    end

    def load_config(path)
      Config.new.load(path)
    end

    def start(name, config)
      bridge = Bridge.new(name, config)
      bridge.start
    end
  end
end

GEB = GerritEventBridge
