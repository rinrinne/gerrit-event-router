module GerritEventBridge
  module Config
    module Broker
      class Base < GerritEventBridge::Config::Base
        def initialize(name, uri)
          super(name, uri)
        end
      end
    end
  end
end
