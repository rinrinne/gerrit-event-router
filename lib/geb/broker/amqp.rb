module GerritEventBridge
  module Broker
    class AMQP < Base
      def initialize(broker)
        super(broker)
      end
    end
  end
end
