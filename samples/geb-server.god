# -*- coding: utf-8 -*-
$:.unshift File.join(File.dirname(File.expand_path(__FILE__)), "lib")
require 'geb'

GEB_ROOT   = "/home/user/git/gerrit-event-bridge"
RBENV_ROOT = "/home/user/.rbenv"
RBENV_VER  = "1.9.3-p362"
LOG_DIR    = "/tmp/geb"

conf = GEB.load_config("#{GEB_ROOT}/geb-server.conf")

conf.gerrits.each do |gerrit|
  God.watch do |w|
    w.name = gerrit.name
    w.group = "geb-servers"
    w.dir = GEB_ROOT
    w.log = "#{LOG_DIR}/#{gerrit.name}.log"
    w.env = { 'RBENV_ROOT' => "#{RBENV_ROOT}",
              'RBENV_VERSION' => "#{RBENV_VER}" }
    w.start = "#{RBENV_ROOT}/bin/rbenv exec #{GEB_ROOT}/geb-server -c #{GEB_ROOT}/geb-server.conf -n #{gerrit.name} -d"
    w.keepalive
  end
end
