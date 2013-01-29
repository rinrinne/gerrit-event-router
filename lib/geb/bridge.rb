module GerritEventBridge
  class Bridge
    def initialize(name, config)
      @name = name
      begin
        @gerrit = config.gerrits[name]
        raise "Gerrit name is not found: #{name}" unless @gerrit
        @broker = config.brokers[@gerrit.broker]
        raise "Broker name is not found: #{@gerrit.broker}" unless @broker

        GEB.logger.info "Configured bridge: gerrit(#{@gerrit.name}) -> broker(#{@broker.name})"
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
        GEB.logger.info "Terminated by INT"
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

        fail_conn = Proc.new { GEB.logger.warn "[AMQP] connection failure" }
        fail_auth = Proc.new { GEB.logger.warn "[AMQP] authentication failure" }

        EM.run do
          EM::Ssh.start(uri.host, uri.user, :port => uri.port) do |connection|
            connection.errback do |err|
              GEB.logger.error { "#{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              GEB.logger.info("Start gerrit connection, process #{$$}")
              AMQP.connect(@broker.uri,
                           :on_tcp_connection_failure => fail_conn,
                           :on_possible_authentication_failure => fail_auth) do |amqp_conn, open_ok|
                AMQP::Channel.new(amqp_conn, AMQP::Channel.next_channel_id, :auto_recovery => true) do |amqp_ch, open_ok|
                  ex_type = @broker.exchange['type']
                  ex_name = @broker.exchange['name']
                  amqp_ex = case ex_type 
                            when "direct"
                              amqp_ch.direct(ex_name)
                            when "fanout"
                              amqp_ch.fanout(ex_name)
                            when "topic"
                              amqp_ch.topic(ex_name)
                            end
                  session.exec(@gerrit.command) do |channel, stream, data|
                    channel.on_data do |ch, data|
                      str = %Q({"host":"#{uri.host}","user":"#{uri.user}","event":#{data.strip}})
                      amqp_ex.publish(str, :routing_key => @gerrit.routingkey)
                      GEB.logger.debug { str }
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
