#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting Minikube..."
minikube start

echo "==> Building mutable JAR..."
quarkus build

echo "==> Building JVM Docker image..."
cd toy-project
docker build -f src/main/docker/Dockerfile.jvm -t toy-project-jvm .
cd ..

echo "==> Loading image into Minikube..."
minikube image load toy-project-jvm

echo "==> Deploying to Minikube..."
kubectl apply -f k8s/
kubectl rollout status deployment/postgres
kubectl rollout status deployment/toy-project

NODE_PORT=$(kubectl get svc toy-project -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
MINIKUBE_IP=$(minikube ip)

echo ""
echo "Setup complete."
echo ""
echo "App URL: http://${MINIKUBE_IP}:${NODE_PORT}/calculator/add?a=3&b=4"
echo ""
echo "To start remote dev mode:"
echo ""
echo "  cd toy-project && ./mvnw quarkus:remote-dev \\"
echo "    -Dquarkus.live-reload.url=http://${MINIKUBE_IP}:${NODE_PORT}"
echo ""
echo "To tear down: minikube delete"
