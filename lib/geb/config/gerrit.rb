module GerritEventBridge
  class Config
    class Gerrit < Base
      DEFAULT_PORT = 29418
      COMMAND = 'gerrit stream-events'

      def initialize(name, uri, keyfile, broker, routingkey)
        super(name, uri)
        @keyfile = keyfile
        @broker = broker
        @routingkey = routingkey
      end

      def default_port
        DEFAULT_PORT
      end

      def command
        COMMAND
      end

      attr_reader :keyfile, :broker, :routingkey
    end
  end
end

