require 'yaml'
require 'uri'

module GerritEventBridge
  class Config
    class Broker < Base
      def initialize(name, uri, exchange)
        super(name, uri)
        @exchange = exchange
      end

      attr_reader :exchange
    end
  end
end

