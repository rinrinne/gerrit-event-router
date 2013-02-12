# -*- coding: utf-8 -*-
$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), "lib")
require 'ger'

GER_ROOT   = "/home/user/git/gerrit-event-router"
RBENV_ROOT = "/home/user/.rbenv"
RBENV_VER  = "1.9.3-p362"
LOG_DIR    = "/tmp/ger"

conf = GER.load_config("#{GER_ROOT}/gerouter.conf")

conf.gerrits.each do |gerrit|
  God.watch do |w|
    w.name = gerrit.name
    w.group = "gerouters"
    w.dir = GER_ROOT
    w.log = "#{LOG_DIR}/#{gerrit.name}.log"
    w.env = { 'RBENV_ROOT' => "#{RBENV_ROOT}",
              'RBENV_VERSION' => "#{RBENV_VER}" }
    w.start = "#{RBENV_ROOT}/bin/rbenv exec #{GER_ROOT}/gerouter -c #{GER_ROOT}/gerouter.conf -n #{gerrit.name} -d"
    w.keepalive
  end
end
