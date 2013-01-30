module GerritEventBridge
  module Config
    class Generic
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

      def initialize(path)
        @gerrits = Array.new
        @brokers = Array.new

        open(path || GEB.DEFAULT_CONFIG) do |stream|
          YAML.load_stream(stream, path) do |obj|
            if obj.instance_of?(GEB::Config::Gerrit)
              @gerrits << obj
            elsif obj.kind_of?(GEB::Config::Broker::Base)
              @brokers << obj
            end
          end
        end
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

      attr_accessor :gerrits, :brokers
    end
  end
end
