# Quarkus development in kubernetes

This project is for showcasing quarkus remote dev https://quarkus.io/guides/maven-tooling#remote-development-mode.

The idea is that sometimes we would like to use hot reload on a container running inside kubernetes.
For example, we are unable to setup the whole dev environment on the local machine due to
complexity or resource constraints.

The important part is

```text
quarkus.package.jar.type=mutable-jar
quarkus.live-reload.password=devpassword
%remote-dev.quarkus.live-reload.url=http://192.168.49.2:30208
```

in [`toy-project/src/main/resources/application.properties`](toy-project/src/main/resources/application.properties).
The [docker file](toy-project/src/main/docker/Dockerfile.jvm) also has to be prepared in a specific way

```Dockerfile
# important part
USER root
RUN chown -R default:default /deployments
RUN chmod o+rw -R /deployments
USER 185
```

As far as my testing went, the service was hot reloaded, but the hot reload was not triggered for the dependency.