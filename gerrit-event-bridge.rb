#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), "lib")

require 'rubygems'
require 'optparse'
require 'yaml'
require 'uri'
require 'logger'
require 'eventmachine'
require 'em-ssh'
require 'amqp'
require 'geb'

Version = '1.0'
GEB.logger(GEB::LOG_NORMAL).progname = GEB::NAME

begin
  OPTS = {}
  OptionParser.new do |opt|
    opt.on('d', '--debug', "Debug mode") do
      OPTS[:debug] = true
    end
    opt.on('-c CONFIGFILE', '--config', 'Path to config file') do |v|
      OPTS[:config] = v
    end
    opt.on('-n NAME', '--name', 'Name of gerrit') do |v|
      OPTS[:name] = v
    end
    opt.parse(ARGV)
  end

  GEB.logger.level = GEB::LOG_DEBUG if OPTS[:debug]

  conf = GEB.load_config(OPTS[:config])

  if OPTS[:name]
    GEB.start(OPTS[:name], conf)
  else
    STDOUT.puts conf.names
  end

rescue => e
  GEB.logger.error("#{e.message} (#{e.class})")
  GEB.logger.debug("TRACE -->\nT, #{e.backtrace.join("\nT, ")}")
  exit 1
end
