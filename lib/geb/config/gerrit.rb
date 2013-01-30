module GerritEventBridge
  module Config
    class Gerrit < Base
      DEFAULT_PORT = 29418
      COMMAND = 'gerrit stream-events'

      def initialize(name, uri, ssh_key, broker, routing_key)
        super(name, uri)
        @ssh_key = ssh_key
        @broker = broker
        @routing_key = routing_key
      end

      def default_port
        DEFAULT_PORT
      end

      def command
        COMMAND
      end

      attr_reader :ssh_key, :broker, :routing_key
    end
  end
end

