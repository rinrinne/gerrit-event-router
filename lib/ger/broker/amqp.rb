# -*- coding: utf-8 -*-
module GerritEventRouter
  module Broker
    class AMQP < Base
      HEADER = '[Broker::AMQP]'

      class Config < GerritEventRouter::Broker::Config::Base
        def initialize(name, uri, user, exchange)
          super(name, uri)
          @user = user
          @exchange = exchange
        end

        def header
          AMQP::HEADER
        end

        attr_reader :user, :exchange
      end

      def initialize(broker)
        super(broker)
        @headers = {
          :content_type => 'application/json',
          :user_id => @broker.user,
          :app_id => GER::NAME
        }
        @connection = nil
        @exchange = nil
      end

      def connect(&block)
        begin
          @connection = ::AMQP.connect(@broker.uri) do |connection|
            generate_channel(connection)
            block.call self if block
          end

          @connection.on_tcp_connection_loss(&method(:conn_loss))
          @connection.on_connection_interruption(&method(:conn_intp))
          @connection.on_recovery(&method(:generate_channel))

          self
        rescue ::AMQP::PossibleAuthenticationFailureError => afe
          auth_failure(afe)
        rescue ::AMQP::TCPConnectionFailed => e
          conn_failure(e)
        end
      end

      def send(data, param)
        param[:timestamp] = Time.now.to_i
        @exchange.publish(data, @headers.merge(param)) do
          GER.logger.debug "#{HEADER} Published time: #{param[:timestamp]}"
          GER.logger.debug "#{HEADER} Published content: #{data}"
        end
      end

      def channel
        if @exchange then
          @exchange.channel
        else
          nil
        end
      end

      def generate_channel(connection = nil)
        conn = connection || @connection
        channel = ::AMQP::Channel.new(conn, ::AMQP::Channel.next_channel_id)
        channel.auto_recovery = true
        channel.on_error do |ch, channel_close|
          raise channel_close.reply_text
        end

        @exchange = ::AMQP::Exchange.new(channel,
                                         @broker.exchange['type'].to_sym,
                                         @broker.exchange['name'])
      end

      def conn_failure(err)
        GER.logger.error "#{HEADER} TCP connection failed, as expcted."
        EM.stop if EM.reactor_running?
      end

      def auth_failure(err)
        GER.logger.error "#{HEADER} Authentication failed, as expcted, caught #{afe.inspect}"
        EM.stop if EM.reactor_running?
      end

      def conn_loss(connection, settings)
        if connection.error? then
          GER.logger.warn "#{HEADER} Connection lost. reconnectiong..."
          connection.reconnect(false, 1)
        end
      end

      def conn_intp(connection)
        if connection.error? then
          GER.logger.warn "#{HEADER} Connection interrupton. reconnectiong..."
          connection.reconnect(false, 1)
        end
      end

      attr_reader :connection, :exchange
    end
  end
end
