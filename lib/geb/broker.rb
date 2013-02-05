module GerritEventBridge
  module Broker
    class Base
      def initialize(broker)
        @broker = broker
      end

      def send(data)
      end

    end

    module Config
      class Base < GerritEventBridge::Config::Base
        def initialize(name, uri)
          super(name, uri)
        end
      end
    end

    class << self
      def connect(broker, &block)
        if broker.instance_of?(GEB::Broker::AMQP::Config) then
          GEB::Broker::AMQP.new(broker).connect(&block)
        end
      end
    end
  end
end
