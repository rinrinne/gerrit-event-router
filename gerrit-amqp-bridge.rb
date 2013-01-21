#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'em-ssh'
require 'amqp'
require 'optparse'

Version = '1.0'
OPTS = {}

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

abort('-n is not specified.') unless OPTS[:name]
OPTS[:config] = '/etc/gerrit-amqp-bridge.conf' unless OPTS[:config]

EM.run do
  Signal.trap("INT") do
    EM.stop
  end

  begin
    AMQP.connect('amqp://localhost:3456',
                 :on_tcp_connection_failure => Proc.new {EM.stop},
                 :on_possible_authentication_failure => Proc.new {EM.stop}) do |amqp_conn|
      amqp_ch = AMQP::Channel.new(amqp_conn)
      amqp_ex = amqp_ch.fanout("gerrit.event")
      amqp_ch.queue("test").bind(amqp_ex)

      EM::Ssh.start('review.sonyericsson.net', 'nobuhiro.hayashi', :port => 29418) do |connection|
        connection.errback do |err|
          $stderr.puts "#{err} (#{err.class})"
          EM.stop
        end

        connection.callback do |session|
          session.exec('gerrit stream-events') do |channel, stream, data|
            channel.on_data do |ch, data|
              str = %Q({"host":"localhost","user":"testuser","event":#{data.strip}})
              amqp_ex.publish(str)
              $stdout.puts str
            end
          end
        end
      end
    end
  rescue => e
    $stderr.puts "#{e} (#{e.class})"
    EM.stop
  end
end
