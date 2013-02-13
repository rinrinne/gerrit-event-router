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
        def initialize(name, uri, mode)
          super(name, uri)
          @mode = mode || "normal"
        end

        attr_reader :mode
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
