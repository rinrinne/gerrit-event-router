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
        GEB.logger.debug "Receive signal: INT"
        EM.add_timer(1) do
          GEB.logger.info "Terminated by INT"
          EM.stop
        end
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

        amqp_connection_options = {
          :on_tcp_connection_failure =>
            Proc.new { GEB.logger.warn "#{GEB::AMQP_HEADER} connection failure" },
          :on_possible_authentication_failure =>
            Proc.new { GEB.logger.warn "#{GEB::AMQP_HEADER} authentication failure" }
        }

        exchange_headers = {
          :routing_key => @gerrit.routing_key,
          :content_type => 'application/json',
          :user_id => @broker.user,
          :app_id => GEB::NAME
        }

        EM.run do
          EM::Ssh.start(uri.host, uri.user, :port => uri.port) do |connection|
            connection.errback do |err|
              GEB.logger.error { "#{GEB::GERRIT_HEADER} #{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              GEB.logger.info("#{GEB::GERRIT_HEADER} connection established.")
              AMQP.connect(@broker.uri, amqp_connection_options) do |client, open_ok|
                AMQP::Channel.new(client, AMQP::Channel.next_channel_id, :auto_recovery => true) do |amqp_ch, open_ok|
                  AMQP::Exchange.new(amqp_ch, @broker.exchange['type'].to_sym, @broker.exchange['name']) do |exchange|
                    session.exec(@gerrit.command) do |channel, stream, data|
                      channel.on_data do |ch, data|
                        exchange_headers[:timestamp] = Time.now.to_i
                        str = %Q({"version":"#{GEB::EVENT_SCHEMA_VERSION}","host":"#{uri.host}","user":"#{uri.user}","event":#{data.strip}})
                        exchange.publish(str, exchange_headers) do
                          GEB.logger.debug "#{GEB::AMQP_HEADER} Published time: #{exchange_headers[:timestamp]}"
                          GEB.logger.debug "#{GEB::AMQP_HEADER} Published content: #{str}"
                        end
                      end
                    end
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
