# -*- coding: utf-8 -*-
module GerritEventRouter
  class Gerrit
    HEADER = '[gerrit]'

    class Config < GerritEventRouter::Config::Base
      DEFAULT_PORT = 29418
      COMMAND = 'gerrit stream-events'
      VERSION = 'gerrit version'

      def initialize(name, uri, ssh_keys, broker, routing_key)
        super(name, uri)
        if ssh_keys.kind_of? Array then
          @ssh_keys = ssh_keys
        elsif ssh_keys.kind_of? String then
          @ssh_keys= [ ssh_keys ]
        end
        @broker = broker
        @routing_key = routing_key
      end

      def default_port
        DEFAULT_PORT
      end

      def command
        COMMAND
      end

      def version
        VERSION
      end

      def header
        Gerrit::HEADER
      end

      attr_reader :ssh_keys, :broker, :routing_key
    end

    def initialize(gerrit)
      @gerrit = gerrit
    end
  end
end
