module GerritEventBridge
  class Bridge
    def initialize(name, config)
      @name = name
      begin
        @gerrit = config.gerrits[name]
        raise "Gerrit name is not found: #{name}" unless @gerrit
        @broker = config.brokers[@gerrit.broker]
        raise "Broker name is not found: #{@gerrit.broker}" unless @broker

        GEB.logger.info "Configured bridge: #{GEB::GERRIT_HEADER}(#{@gerrit.name}) -> broker#{GEB::AMQP_HEADER}(#{@broker.name})"
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

        EM.run do
          EM::Ssh.start(uri.host, uri.user, :port => uri.port) do |connection|
            connection.errback do |err|
              GEB.logger.error { "#{GEB::GERRIT_HEADER} #{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              GEB.logger.info("#{GEB::GERRIT_HEADER} connection established.")

              GEB::Broker.connect(@broker) do |broker|
                GEB.logger.info("#{GEB::AMQP_HEADER} connection established.")

                session.exec(@gerrit.command) do |channel, stream, data|
                  channel.on_data do |ch, data|
                    str = %Q({"version":"#{GEB::EVENT_SCHEMA_VERSION}","host":"#{uri.host}","user":"#{uri.user}","event":#{data.strip}})
                    broker.send(str, :routing_key => @gerrit.routing_key, :timestamp => Time.now.to_i)
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
