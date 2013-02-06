module GerritEventBridge
  class Gerrit
    HEADER = '[gerrit]'

    class Config < GerritEventBridge::Config::Base
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

      def header
        Gerrit::HEADER
      end

      attr_reader :ssh_key, :broker, :routing_key
    end

    def initialize(gerrit)
      @gerrit = gerrit
    end
  end
end
