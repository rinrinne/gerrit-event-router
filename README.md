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

Install gem

```
$ gem install gerouter
```

Command help

```
$ bundle exec gerouter --help
Usage: gerouter [options]
    -d, --debug                      Debug mode
    -c, --config CONFIGFILE          Path to config file
    -n, --name NAME                  Name of gerrit
```

You should specify -c and -n options.

```
$ bundle exec gerouter -c gerouter.conf -n foobar
```

If -n is not specified, gerouter displays name list.

```
$ bundle exec gerouter -c gerouter.conf
---
:gerrit:
- foobar
:broker:
- foo
```

This application runs on user process in foreground. If you want to run as daemon, recommend to use [God][god]. Samples are stored in [here][samples].

[god]: http://godrb.com/ "God"
[samples]: https://github.com/rinrinne/gerrit-event-router/tree/master/samples "samples"


Config
---------------------------

<script src="https://gist.github.com/rinrinne/4563261.js"></script>

First prototype: https://gist.github.com/4563261





License
===========================

MIT License

Copyright
===========================

Copyright (c) 2013 rinrinne a.k.a. rin_ne
