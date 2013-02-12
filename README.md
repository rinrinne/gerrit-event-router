gerouter: Gerrit Event Router
===========================

* Author: rinrinne
* Repository: https://github.com/rinrinne/gerrit-event-router

Synopsis
---------------------------

gerouter is a server application for routing [Gerrit][gerrit] events to message broker.
Now only AMQP broker is supported (recommend [RabbitMQ][rabbitmq] as message queue server)

[gerrit]: https://code.google.com/p/gerrit/ "Gerrit Code Review"
[rabbitmq]: http://www.rabbitmq.com/ "RabbitMQ"

Motivation
---------------------------

Gerrit provides events via ssh stream. Client can receive them using ssh connection. But both of them has no dedicated queue. It means that client may miss many events if ssh is disconnected.

Gerrit events are not required to be processed in real-time. So we can improve this by adding a dedicated and robust queue.

This application can achieve this purpose by a combination with message queue service.


Usage
--------------------------

Install gem:

```console
$ gem install gerouter
```

Install from repository:

```console
$ rake build
$ bundle install
```

Command help:

```console
$ bundle exec gerouter --help
Usage: gerouter [options]
    -d, --debug                      Debug mode
    -c, --config CONFIGFILE          Path to config file
    -n, --name NAME                  Name of gerrit
```

You should specify -c and -n options.

```console
$ bundle exec gerouter -c gerouter.conf -n foobar
```

If -n is not specified, gerouter displays name list.

```console
$ bundle exec gerouter -c gerouter.conf
---
:gerrit:
- foobar
:broker:
- foo
```

This application runs on user process in foreground. If you want to run as daemon, recommend to use [God][god]. Samples are stored in [here][samples].

Note that sample is configured to use [shared rbenv][sharedrbenv]

[god]: http://godrb.com/ "God"
[samples]: https://github.com/rinrinne/gerrit-event-router/tree/master/samples "samples"
[sharedrbenv]: https://github.com/rinrinne/install-shared-rbenv "Install shared rbenv"

Config
---------------------------

Sample of config is also stored in [here][samples].

* YAML format with object information
* Gerrit and broker items
* You can include multiple item
* Broker in Gerrit has the broker name
* Broker can consolidate events in multiple Gerrit


Encapsulated Gerrit event
---------------------------

Gerrit event which is sent to broker is encapsulated in order to consolidate them in multiple Gerrit.

```json
{
"version":"1",
"host":"gerrit hostname",
"event":{"ORIGINAL EVENT"} 
}
```

License
---------------------------

MIT License

Copyright
---------------------------

Copyright (c) 2013 rinrinne a.k.a. rin_ne
