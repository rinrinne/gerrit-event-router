module GerritEventBridge
  module Broker
    class Base
      def initialize(broker)
        @broker = broker
      end

      def send(data)
      end
    end

    class << self
      def load(broker)
        if broker.instance_of?(GEB::Config::Broker::AMQP) then
          GEB::Broker::AMQP.new(broker)
        end
      end
    end
  end
end
