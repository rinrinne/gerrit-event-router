$:.unshift File.dirname(__FILE__)

require 'config'

conf = GerritEventBridge::Config.parse '../../gerrit-event-bridge.yaml'
p conf
