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

DEFAULT_CONFIG = '/etc/gerrit-event-bridge.conf'

Version = '1.0'
GEB.logger.progname = 'GEB'

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

  GEB.logger.level = ::Logger::DEBUG if OPTS[:debug]

  conf = GEB::Config.load(OPTS[:config] || DEFAULT_CONFIG)
  gerrit = nil
  broker = nil

  if OPTS[:name]
    gerrit = conf.gerrits[OPTS[:name]]
    raise "Gerrit name is not found: #{OPTS[:name]}" unless gerrit
    broker = conf.brokers[gerrit.broker]
    raise "Broker name is not found: #{gerrit.broker}" unless broker
  else
    STDOUT.puts conf.names
    exit 0
  end

  bridge = GEB::Bridge.new(OPTS[:name], conf)
  bridge.start


rescue => e
  GEB.logger.error { e.message }
  exit 1
end
 
=begin
EM.run do
  Signal.trap("INT") do
    EM.stop
  end

  begin
    GEB.logger.info { "begin" }
    gerrit = URI.parse(conf["gerrit"]["url"])
    EM::Ssh.start(gerrit.host, gerrit.user, :port => gerrit.port) do |connection|
      connection.errback do |err|
        GEB.logger.warn { "#{err} (#{err.class})" }
        EM.stop
      end

      connection.callback do |session|
        AMQP.connect(conf["bridge"]["url"],
                     :on_tcp_connection_failure => Proc.new {$stderr.puts "[AMQP] connection failure"; EM.stop},
                     :on_possible_authentication_failure => Proc.new {$stderr.puts "[AMQP] authentication failure"; EM.stop}) do |amqp_conn|
          amqp_ch = AMQP::Channel.new(amqp_conn)
          amqp_ex = amqp_ch.fanout(conf["bridge"]["param"]["exchange-name"])

          session.exec('gerrit stream-events') do |channel, stream, data|
            channel.on_data do |ch, data|
              str = %Q({"host":"#{gerrit.host}","user":"#{gerrit.user}","event":#{data.strip}})
              amqp_ex.publish(str)
              GEB.logger.debug { str }
            end
          end

        end
      end
    end
  rescue => e
    GEB.logger.error { "#{e} (#{e.class})" }
    GEB.logger.debug { e.backtrace.join("\n") }
    EM.stop
  end
end
=end
