module GerritEventBridge
  NAME = 'GEB'
  DEFAULT_CONFIG = '/etc/gerrit-event-bridge.conf'
  LOG_NORMAL  = ::Logger::INFO
  LOG_DEBUG   = ::Logger::DEBUG

  GERRIT_HEADER = '[gerrit]'
  AMQP_HEADER   = '[AMQP]'

  EVENT_SCHEMA_VERSION = '1'
end
