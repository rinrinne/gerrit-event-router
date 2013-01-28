module GerritEventBridge
  class Bridge
    def initialize(name, config)
      @name = name
      @config = config
    end

    def start
      Signal.trap("INT") do
        EM.stop
      end

      begin
        gerrit = @config.gerrits[@name]
        broker = @config.brokers[gerrit.broker]

        uri = URI.parse(gerrit.uri)
        uri.port = gerrit.default_port unless uri.port

        fail_conn = Proc.new { GEB.logger.error "[AMQP] connection failure" }
        fail_auth = Proc.new { GEB.logger.error "[AMQP] authentication failure" }

        EM.run do
          EM::Ssh.start(uri.host, uri.user, :port => uri.port) do |connection|
            connection.errback do |err|
              GEB.logger.warn { "#{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              AMQP.connect(broker.uri,
                           :on_tcp_connection_failure => fail_conn,
                           :on_possible_authentication_failure => fail_auth) do |amqp_conn, open_ok|
                AMQP::Channel.new(amqp_conn, AMQP::Channel.next_channel_id, :auto_recovery => true) do |amqp_ch, open_ok|
                  ex_type = broker.exchange["type"]
                  ex_name = broker.exchange["name"]
                  amqp_ex = case ex_type 
                            when "direct"
                              amqp_ch.direct(ex_name)
                            when "fanout"
                              amqp_ch.fanout(ex_name)
                            when "topic"
                              amqp_ch.topic(ex_name)
                            end
                  session.exec(gerrit.command) do |channel, stream, data|
                    channel.on_data do |ch, data|
                      str = %Q({"host":"#{uri.host}","user":"#{uri.user}","event":#{data.strip}})
                      amqp_ex.publish(str, :routing_key => gerrit.routingkey)
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
