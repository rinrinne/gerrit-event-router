require 'yaml'
require 'uri'

module GerritEventBridge
  class Config
    class Broker < Base
      def initialize(name, uri, user, exchange)
        super(name, uri)
        @user = user
        @exchange = exchange
      end

      attr_reader :user, :exchange
    end
  end
end

