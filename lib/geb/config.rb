require 'yaml'
require 'uri'

module GerritEventBridge
  class Config

    class Array < ::Array
      def [](key)
        unless key.kind_of?(Integer)
          self.each do |item|
            if item.name == key then
              return item
            end
          end
          nil
        else
          super(key)
        end
      end
    end

    class Base
      def initiallize(name, uri)
        @name = name
        @uri = uri.gsiub(%r|/+$|, "")
      end

      attr_reader :name, :uri
    end

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

    class Broker < Base
      def initialize(name, uri, exchange)
        super(name, uri)
        @exchange = exchange
      end

      attr_reader :exchange
    end

    def Config.load(path)
      conf = new()
      open(path) do |stream|
        YAML.load_stream(stream, path) do |obj|
          if obj.instance_of?(Gerrit)
            conf.gerrits << obj
          elsif obj.kind_of?(Broker)
            conf.brokers << obj
          end
        end
      end
      conf
    end

    def names(to_yaml = true)
      h = Hash.new
      h[:gerrit] = @gerrits.map {|item| item.name}
      h[:broker] = @brokers.map {|item| item.name}
      if to_yaml then
        YAML.dump(h)
      else
        h
      end
    end

    def initialize
      @gerrits = Array.new
      @brokers = Array.new
    end

    attr_accessor :gerrits, :brokers
  end
end

