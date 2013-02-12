# -*- coding: utf-8 -*-
$:.unshift File.dirname(File.expand_path(__FILE__))

require 'logger'
require 'yaml'
require 'uri'
require 'ger/constants'
require 'ger/config'
require 'ger/router'
require 'ger/gerrit'
require 'ger/broker'
require 'ger/broker/amqp'

module GerritEventRouter
  class << self
    attr_writer :logger
    def logger(level = ::Logger::INFO)
      @logger ||= ::Logger.new(STDOUT).tap {|l| l.level = level }
    end

    def load_config(path)
      Config.new.load(path)
    end

    def start(name, config)
      router = Router.new(name, config)
      router.start
    end
  end
end

GER = GerritEventRouter
