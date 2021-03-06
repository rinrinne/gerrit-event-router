# -*- coding: utf-8 -*-
module GerritEventRouter
  class Router
    def initialize(name, appid, config)
      @name = name
      @appid = appid
      begin
        @gerrit = config.gerrits[name]
        raise "Gerrit name is not found: #{name}" unless @gerrit
        @broker = config.brokers[@gerrit.broker]
        raise "Broker name is not found: #{@gerrit.broker}" unless @broker

        GER.logger.info "Configured router: #{@gerrit.header}(#{@gerrit.name}) -> broker#{@broker.header}(#{@broker.name})"
        @configured = true
      rescue
        @configured = false
        raise
      end
    end

    def header(provider)
        headers = {
          "gerrit-name" => provider["name"],
          "gerrit-host" => provider["host"],
          "gerrit-scheme" => provider["scheme"],
          "gerrit-port" => provider["port"],
          "gerrit-front-url" => provider["url"],
          "gerrit-version" => provider["version"]
        }
        return headers
    end

    def start
      raise "Router still not be configured" unless @configured

      Signal.trap(:INT) do
        Thread.new do
          GER.logger.info "Receive signal: INT. terminating."
        end
        EM.stop
      end

      Signal.trap(:TERM) do
        Thread.new do
          GER.logger.info "Receive signal: TERM. terminating."
        end
        EM.stop
      end

      Signal.trap(:USR2) do
        Thread.new do
          GER.logger.debug "Receive signal: USR2"
        end
        if GER.logger.level == GER::LOG_NORMAL then
          GER.logger.level = GER::LOG_DEBUG
        else
          GER.logger.level = GER::LOG_NORMAL
        end
      end

      begin
        uri = URI.parse(@gerrit.uri)
        uri.port = @gerrit.default_port unless uri.port
        ssh_options = { :port => uri.port }
        ssh_options[:keys] = @gerrit.ssh_keys if @gerrit.ssh_keys

        provider = {
          "name" => @gerrit.name,
          "host" => uri.host,
          "port" => uri.port.to_s,
          "scheme" => "ssh",
          "url" => @gerrit.weburl
        }

        EM.run do
          EM::Ssh.start(uri.host, uri.user, ssh_options) do |connection|
            connection.errback do |err|
              GER.logger.error { "#{@gerrit.header} #{err} (#{err.class})" }
              EM.stop
            end

            connection.callback do |session|
              GER.logger.info("#{@gerrit.header} connection established.")

              GER::Broker.connect(@broker) do |broker|
                GER.logger.info("#{@broker.header} connection established.")
                GER.logger.debug("#{@broker.header} channel id = #{broker.channel.id}")

                session.exec(@gerrit.version) do |channel, stream, data|
                  if data then
                    version = data.strip.delete("gerrit version")
                    provider["version"] = version
                    GER.logger.info("version: #{version}")
                  end
                end

                session.exec(@gerrit.command) do |channel, stream, data|
                  channel.on_data do |ch, data|
                    if @broker.mode == "raw" then
                      str = %Q(#{data.strip})
                    else
                      json = JSON.parse(data.strip)
                      provider["event_id"] = Digest::SHA256.hexdigest(data.strip)
                      json["provider"] = provider
                      str = JSON.generate(json)
                    end
                    broker.send(str, :app_id => @appid, :routing_key => @gerrit.routing_key, :headers => header(provider))
                  end
                end
              end
            end
          end
        end
      rescue => e
        GER.logger.error { "#{e} (#{e.class})" }
        GER.logger.debug { e.backtrace.join("\n") }
        EM.stop
      end
    end
  end
end
