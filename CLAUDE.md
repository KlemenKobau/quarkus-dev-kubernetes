# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A multi-module Maven project used for showcasing Quarkus remote development mode inside Kubernetes (Minikube). It consists of:
- `calculator-lib/` — a plain CDI library with a `CalculatorService` (add, subtract, multiply)
- `toy-project/` — a Quarkus REST app that delegates to `CalculatorService` via `GET /calculator/{add,subtract,multiply}`

- **Framework:** Quarkus 3.35.4
- **Java:** 25
- **Stack:** Jakarta REST, Quarkus ARC (CDI), MapStruct, Agroal + PostgreSQL JDBC

## Commands

All multi-module Maven commands run from the **repo root** using the wrapper in `toy-project/`:

```bash
# Build all modules (installs calculator-lib then toy-project)
toy-project/mvnw install

# Dev mode with live reload (local, no Kubernetes — Dev UI at http://localhost:8080/q/dev/)
cd toy-project && ./mvnw quarkus:dev

# Run unit tests
toy-project/mvnw test

# Run single test class
cd toy-project && ./mvnw test -Dtest=CalculatorResourceTest

# Run all tests (unit + integration via failsafe)
cd toy-project && ./mvnw verify

# Build JVM JAR (mutable-jar type is set in application.properties)
cd toy-project && ./mvnw package

# Build native executable (requires Docker)
cd toy-project && ./mvnw package -Dnative -Dquarkus.native.container-build=true
```

## Docker

Four Dockerfile variants live in `toy-project/src/main/docker/`:
- `Dockerfile.jvm` — standard JVM deployment (UBI 9 + OpenJDK 25)
- `Dockerfile.native` — GraalVM native executable (UBI 9 minimal)
- `Dockerfile.legacy-jar` — single fat JAR
- `Dockerfile.native-micro` — minimal native variant

```bash
# Build and run JVM image (run from toy-project/)
cd toy-project
docker build -f src/main/docker/Dockerfile.jvm -t toy-project-jvm .
docker run -i --rm -p 8080:8080 toy-project-jvm
```

## Testing Architecture

- `@QuarkusTest` classes (surefire): unit tests, run with `./mvnw test`
- `@QuarkusIntegrationTest` classes (failsafe): integration tests, require a packaged app, run with `./mvnw verify`

## Kubernetes

Minikube is the target runtime. Start with `minikube start`. Kubernetes manifests live in `k8s/`:
- `postgres.yaml` — PostgreSQL 17 Deployment + ClusterIP Service
- `configmap.yaml` — App config and Quarkus remote dev settings
- `toy-project.yaml` — App Deployment + NodePort Service

```bash
kubectl apply -f k8s/
```
