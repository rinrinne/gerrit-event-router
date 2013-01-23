#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'yaml'
require 'uri'
require 'logger'
require 'eventmachine'
require 'em-ssh'
require 'amqp'

DEFAULT_CONFIG = '/etc/gerrit-event-bridge.conf'

Version = '1.0'
OPTS = {}
conf = nil

$logger = ::Logger.new(STDOUT)
$logger.level = ::Logger::DEBUG

begin
  OptionParser.new do |opt|
    opt.on('-c CONFIGFILE', '--config', 'Path to config file') do |v|
      OPTS[:config] = v
    end
    opt.parse(ARGV)
  end
  OPTS[:config] = DEFAULT_CONFIG unless OPTS.has_key?(:config)

  open(OPTS[:config]) do |file|
    conf = YAML.load(file)
    raise "No configuration in #{OPTS[:config]}" unless conf
    raise "No gerrit configuration in #{OPTS[:config]}" unless conf.has_key?("gerrit")
    raise "No bridge configuration in #{OPTS[:config]}" unless conf.has_key?("bridge")
  end
rescue => e
  $stderr.puts e
  exit 1
end
 

EM.run do
  Signal.trap("INT") do
    EM.stop
  end

  begin
    $logger.info("begin")
    gerrit = URI.parse(conf["gerrit"]["url"])
    EM::Ssh.start(gerrit.host, gerrit.user, :port => gerrit.port) do |connection|
      connection.errback do |err|
        $logger.warn("#{err} (#{err.class})")
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
              $logger.debug(str)
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
