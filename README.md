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
$ bundle exec gerouter -c gerouer.conf
---
:gerrit:
- foobar
:broker:
- foo
```

This application has user process and runs in foreground. If you want to run as daemon, recommend to use [God][god]. Samples are stored in [here][samples].

Note that sample is configured to use [shared rbenv][sharedrbenv]

[god]: http://godrb.com/ "God"
[samples]: https://github.com/rinrinne/gerrit-event-router/tree/master/samples "samples"
[sharedrbenv]: https://github.com/rinrinne/install-shared-rbenv "Install shared rbenv"

Config
---------------------------

Sample of config is also stored in [here][samples].

* YAML format with object information
* gerrit and broker items
* You can add any number of them
* `broker` in gerrit has the broker name
* gerrits can share one broker 


Stuffed Gerrit event
---------------------------

As below, gerouter stuffs Gerrit event with own object then send to broker.

```json
{
"version":"1",
"host":"gerrit hostname",
"event":{"ORIGINAL EVENT"} 
}
```

If you want to treat raw Gerrit event, you should set "raw" to `mode` in broker config.

License
---------------------------

MIT License

Copyright
---------------------------

Copyright (c) 2013 rinrinne a.k.a. rin_ne
