#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'em-ssh'
require 'amqp'
require 'optparse'
require 'yaml'
require 'uri'

DEFAULT_CONFIG = '/etc/gerrit-event-bridge.conf'

Version = '1.0'
OPTS = {}

conf = nil

begin
  OptionParser.new do |opt|

    opt.on('-n NAME', '--name', 'Name in config') do |v|
      OPTS[:name] = v
    end

    opt.on('-c CONFIGFILE', '--config', 'Path to config file') do |v|
      OPTS[:config] = v
    end

    opt.parse(ARGV)
  end
rescue OptionParser::ParseError => e
  $stderr.puts e
end

abort('-n is not specified.') unless OPTS.has_key?(:name)
OPTS[:config] = DEFAULT_CONFIG unless OPTS.has_key?(:config)

begin
  open(OPTS[:config]) do |file|
    conf = YAML.load(file)[OPTS[:name]]
  end
  raise "#{OPTS[:name]} is not found in config" unless conf
rescue => e
  $stderr.puts e
  exit 1
end
 
gerrit = URI.parse(conf["gerrit"]["url"])

EM.run do
  Signal.trap("INT") do
    EM.stop
  end

  begin
    EM::Ssh.start(gerrit.host, gerrit.user, :port => gerrit.port) do |connection|
      connection.errback do |err|
        $stderr.puts "#{err} (#{err.class})"
        EM.stop
      end

      connection.callback do |session|
        AMQP.connect(conf["target"]["url"],
                     :on_tcp_connection_failure => Proc.new {$stderr.puts "[AMQP] connection failure"; EM.stop},
                     :on_possible_authentication_failure => Proc.new {$stderr.puts "[AMQP] authentication failure"; EM.stop}) do |amqp_conn|
          amqp_ch = AMQP::Channel.new(amqp_conn)
          amqp_ex = amqp_ch.fanout(conf["target"]["exchange"]["name"])

          session.exec('gerrit stream-events') do |channel, stream, data|
            channel.on_data do |ch, data|
              str = %Q({"host":"#{gerrit.host}","user":"#{gerrit.user}","event":#{data.strip}})
              amqp_ex.publish(str)
              $stdout.puts str
            end
          end

        end
      end
    end
  rescue => e
    $stderr.puts "#{e} (#{e.class})"
    $stderr.puts e.backtrace.join("\n")
    EM.stop
  end
end
