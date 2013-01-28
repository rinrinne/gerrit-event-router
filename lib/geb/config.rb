require 'yaml'
require 'uri'

module GerritEventBridge
  module Config

    class Gerrit
      def initialize(name, uri, keyfile, broker, routingkey)
        @name = name
        @uri = uri
        @keyfile = keyfile
        @broker = broker
        @routingkey = routingkey
      end
    end

    class Broker
      def initialize(name, uri, exchange)
        @name = name
        @uri = uri
        @exchange = exchange
      end
    end
  end
end

