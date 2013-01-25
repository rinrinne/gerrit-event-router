require 'yaml'
require 'uri'

module GerritEventBridge
  module Config

    class Base

      def initialize(name)
        @name = name
        @gerrit = nil
        @broker = nil
      end

      attr_reader :name
      attr_accessor :gerrit, :broker
    end

    class Gerrit
      def initialize(hash)
        @uri = URI.parse(hash['uri'])
        @sshkey = hash['sshkey']
      end
      attr_reader :uri, :sshkey
    end

    class Broker

      class Exchange
        def initialize(hash)
          @type = hash['type']
          @name = hash['name']
        end
        attr_reader :type, :name
      end

      def initialize(hash)
        @uri = URI.parse(hash['uri'])
        @exchange = Broker::Exchange.new hash['exchange']
        @routingkey = hash['routingkey']
      end
      attr_reader :uri, :exchange
    end

    def self.parse(path)
      ary = Array.new
      yaml = YAML.load_file(path)
      p yaml
      yaml.each do |item|
        config = Base.new item['name']
        config.gerrit = Gerrit.new item['gerrit']
        config.broker = Broker.new item['broker']
        ary << config
      end
      ary
    end
  end
end

