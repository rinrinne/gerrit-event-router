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
      end
    end
  end
end
