module GerritEventBridge
  module Bridge
    class << self
      def start(config)
        gerrit = URI.parse(config[:gerrit])
        broker = URI.parse(config[:broker])

        EM.run do
          EM::Ssh.start(gerrit.host, gerrit.user, :port => gerrit.port) do |connection|
            connection.errback do |err|
              GEB.logger.warn { "#{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              AMQP.connect(URI.buildZZ
            end
          end
        end
      end
    end
  end
end
