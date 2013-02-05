module GerritEventBridge
  module Broker
    class AMQP < Base

      class Config < GerritEventBridge::Broker::Config::Base
        def initialize(name, uri, user, exchange)
          super(name, uri)
          @user = user
          @exchange = exchange
        end

        attr_reader :user, :exchange
      end

      def initialize(broker)
        super(broker)
        @headers = {
          :content_type => 'application/json',
          :user_id => @broker.user,
          :app_id => GEB::NAME
        }
      end

      def connect(&block)
        begin
          @connection = ::AMQP.connect(@broker.uri) do |connection|
            @channel = ::AMQP::Channel.new(connection, ::AMQP::Channel.next_channel_id)
            @channel.auto_recovery = true
            @channel.on_error do |ch, channel_close|
              raise channel_close.reply_text
            end

            @exchange = ::AMQP::Exchange.new(@channel, @broker.exchange['type'].to_sym, @broker.exchange['name'])

            block.call self if block
          end

          @connection.on_tcp_connection_loss(&method(:conn_loss))
          @connection.on_connection_interruption(&method(:conn_intp))

          self
        rescue ::AMQP::PossibleAuthenticationFailureError => afe
          auth_failure(afe)
        rescue ::AMQP::TCPConnectionFailed => e
          conn_failure(e)
        end
      end

      def send(data, param)
        @exchange.publish(data, @headers.merge(param)) do
          GEB.logger.debug "#{GEB::AMQP_HEADER} Published time: #{param[:timestamp]}"
          GEB.logger.debug "#{GEB::AMQP_HEADER} Published content: #{data}"
        end
      end

      def conn_failure(err)
        GEB.logger.error "#{GEB::AMQP_HEADER} TCP connection failed, as expcted."
        EM.stop if EM.reactor_running?
      end

      def auth_failure(err)
        GEB.logger.error "#{GEB::AMQP_HEADER} Authentication failed, as expcted, caught #{afe.inspect}"
        EM.stop if EM.reactor_running?
      end

      def conn_loss(connection, settings)
        if connection.error? then
          GEB.logger.warn "#{GEB::AMQP_HEADER} Connection lost. reconnectiong..."
          connection.reconnect(false, 1)
        end
      end

      def conn_intp(connection)
        if connection.error? then
          GEB.logger.warn "#{GEB::AMQP_HEADER} Connection interrupton. reconnectiong..."
          connection.reconnect(false, 1)
        end
      end

      attr_reader :connection, :channel, :exchange
    end
  end
end
