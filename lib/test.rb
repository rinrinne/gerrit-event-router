#!/usr/bin/env ruby

$:.unshift File.dirname(File.expand_path(__FILE__))

require 'gmb'
require 'uri'

logger = GMB.logger
logger.level = ::Logger::INFO
logger.info("Hello!")

class Gerrit < URI::Generic

  def hoge
    "fuga"
  end
end

