# -*- coding: utf-8 -*-
module GerritEventRouter
  module Broker
    class Base
      HEADER = '[Broker::Base]'
      def initialize(broker)
        @broker = broker
      end

      def send(data)
      end

      def header
        HEADER
      end

    end

    module Config
      class Base < GerritEventRouter::Config::Base
        def initialize(name, uri)
          super(name, uri)
        end
      end
    end

    class << self
      def connect(broker, &block)
        if broker.instance_of?(GER::Broker::AMQP::Config) then
          GER::Broker::AMQP.new(broker).connect(&block)
        end
      end
    end
  end
end
