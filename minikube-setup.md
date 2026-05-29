# Minikube Setup

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/) — required for Minikube's default driver and for Quarkus Dev Services in tests
- [kubectl](https://kubernetes.io/docs/tasks/tools/) — Kubernetes CLI
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) — local Kubernetes

## Install Minikube

Follow the [official installation instructions](https://minikube.sigs.k8s.io/docs/start/) for your OS, or use a package manager:

```bash
# macOS
brew install minikube

# Linux (Arch)
sudo pacman -S minikube

# Linux (Debian/Ubuntu)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

## Start Minikube

```bash
minikube start
```

Verify it is running:

```bash
minikube status
```

## Point Docker at Minikube's Registry

Before building the app image, point your local Docker daemon at Minikube's internal registry so the image is available to the cluster:

```bash
eval $(minikube docker-env)
```

To revert back to your host Docker daemon:

```bash
eval $(minikube docker-env -u)
```

## Deploy the Application

Build the mutable JAR and Docker image, then apply the manifests:

```bash
# From toy-project/
cd toy-project
./mvnw package -Dquarkus.package.jar.type=mutable-jar
docker build -f src/main/docker/Dockerfile.jvm -t toy-project-jvm .
cd ..

# Deploy PostgreSQL, ConfigMap, and the app
kubectl apply -f k8s/
kubectl rollout status deployment/postgres
kubectl rollout status deployment/toy-project
```

## Start Remote Dev Mode

```bash
NODE_PORT=$(kubectl get svc toy-project -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

cd toy-project
./mvnw quarkus:remote-dev \
  -Dquarkus.live-reload.url=http://$(minikube ip):${NODE_PORT} \
  -Dquarkus.live-reload.password=devpassword
```

Once connected, any change to `calculator-lib` or `toy-project` source is compiled and hot-swapped into the running pod without a redeploy.

## Teardown

```bash
minikube delete
```
