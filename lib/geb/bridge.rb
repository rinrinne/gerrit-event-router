# -*- coding: utf-8 -*-
module GerritEventBridge
  class Bridge
    def initialize(name, config)
      @name = name
      begin
        @gerrit = config.gerrits[name]
        raise "Gerrit name is not found: #{name}" unless @gerrit
        @broker = config.brokers[@gerrit.broker]
        raise "Broker name is not found: #{@gerrit.broker}" unless @broker

        GEB.logger.info "Configured bridge: #{@gerrit.header}(#{@gerrit.name}) -> broker#{@broker.header}(#{@broker.name})"
        @configured = true
      rescue
        @configured = false
        raise
      end
    end

    def start
      raise "Bridge still not be configured" unless @configured

      Signal.trap(:INT) do
        GEB.logger.info "Receive signal: INT. terminating."
        EM.stop
      end

      Signal.trap(:TERM) do
        GEB.logger.info "Receive signal: TERM. terminating."
        EM.stop
      end

      Signal.trap(:USR2) do
        GEB.logger.debug "Receive signal: USR2"
        if GEB.logger.level == GEB::LOG_NORMAL then
          GEB.logger.level = GEB::LOG_DEBUG
        else
          GEB.logger.level = GEB::LOG_NORMAL
        end
      end

      begin
        uri = URI.parse(@gerrit.uri)
        uri.port = @gerrit.default_port unless uri.port
        ssh_options = { :port => uri.port }
        ssh_options[:keys] = @gerrit.ssh_keys if @gerrit.ssh_keys

        EM.run do
          EM::Ssh.start(uri.host, uri.user, ssh_options) do |connection|
            connection.errback do |err|
              GEB.logger.error { "#{@gerrit.header} #{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              GEB.logger.info("#{@gerrit.header} connection established.")

              GEB::Broker.connect(@broker) do |broker|
                GEB.logger.info("#{@broker.header} connection established.")
                GEB.logger.debug("#{@broker.header} channel id = #{broker.channel.id}")

                session.exec(@gerrit.command) do |channel, stream, data|
                  channel.on_data do |ch, data|
                    str = %Q({"version":"#{GEB::SCHEMA_VERSION}","host":"#{uri.host}","user":"#{uri.user}","event":#{data.strip}})
                    broker.send(str, :routing_key => @gerrit.routing_key)
                  end
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
  end
end
