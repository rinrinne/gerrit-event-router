# -*- coding: utf-8 -*-
require 'ger'

RBENV_ROOT = "/home/user/.rbenv"
RBENV_VER  = "1.9.3-p362"
CONFIG     = "/etc/gerouter/gerouter.conf"
LOG_DIR    = "/ver/log/#{GER::NAME}"

conf = GER.load_config("#{CONFIG}")

conf.gerrits.each do |gerrit|
  God.watch do |w|
    w.name = gerrit.name
    w.group = "gerouters"
    w.log = "#{LOG_DIR}/#{gerrit.name}.log"
    w.env = { 'RBENV_ROOT' => "#{RBENV_ROOT}",
              'RBENV_VERSION' => "#{RBENV_VER}" }
    w.start = "#{RBENV_ROOT}/bin/rbenv exec gerouter -c #{CONFIG} -n #{gerrit.name}"
    w.keepalive
  end
end
