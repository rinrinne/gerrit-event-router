module GerritEventBridge
  module Config
    class Base
      def initiallize(name, uri)
        @name = name
        @uri = uri.gsiub(%r|/+$|, "")
      end

      attr_reader :name, :uri
    end

    class << self
      def load(path)
        Generic.new(path)
      end
    end

    attr_accessor :gerrits, :brokers
  end
end

