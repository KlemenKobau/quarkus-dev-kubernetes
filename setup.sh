#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Starting Minikube..."
minikube start

echo "==> Building mutable JAR..."
cd "$SCRIPT_DIR/toy-project"
quarkus build -q

echo "==> Building JVM Docker image..."
docker build -f src/main/docker/Dockerfile.jvm -t toy-project-jvm . -q

echo "==> Loading image into Minikube..."
minikube image load toy-project-jvm

echo "==> Deploying to Minikube..."
cd "$SCRIPT_DIR"
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
