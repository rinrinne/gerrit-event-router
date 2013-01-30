module GerritEventBridge
  module Config
    module Broker
      class AMQP < Base
        def initialize(name, uri, user, exchange)
          super(name, uri)
          @user = user
          @exchange = exchange
        end

        attr_reader :user, :exchange
      end
    end
  end
end
