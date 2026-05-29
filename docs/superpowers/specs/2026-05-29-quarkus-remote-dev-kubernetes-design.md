# Quarkus Remote Dev in Kubernetes — Design Spec

**Date:** 2026-05-29
**Goal:** Showcase Quarkus remote development mode running inside Minikube, with a multi-module Maven project (toy-project + calculator-lib dependency).

---

## 1. Repository Structure

```
quarkus-dev-kubernetes/
├── pom.xml                          ← root parent POM (multi-module)
├── calculator-lib/
│   ├── pom.xml                      ← plain JAR, parent = root POM
│   └── src/main/java/io/kobauk/
│       └── CalculatorService.java
├── toy-project/
│   ├── pom.xml                      ← parent = root POM, dep on calculator-lib
│   ├── src/main/docker/             ← existing Dockerfiles (unchanged)
│   └── src/main/java/io/kobauk/
│       └── CalculatorResource.java  ← replaces TestResource
└── k8s/
    ├── postgres.yaml
    ├── toy-project.yaml
    └── configmap.yaml
```

The root `pom.xml` declares both modules. Maven builds them in dependency order: `calculator-lib` first, then `toy-project`.

---

## 2. calculator-lib Module

Scaffolded with the Quarkus CLI (`quarkus create app` or manually). It is a **plain JAR** — no Quarkus runtime, but it uses `quarkus-arc` annotations for CDI so Quarkus in the toy-project picks the bean up automatically.

**`calculator-lib/pom.xml`:**
- Parent: root POM
- Packaging: `jar`
- Single dependency: `quarkus-arc` with scope `provided` (annotations only; runtime supplied by toy-project)

**`CalculatorService.java`:**

```java
@ApplicationScoped
public class CalculatorService {
    public int add(int a, int b)      { return a + b; }
    public int subtract(int a, int b) { return a - b; }
    public int multiply(int a, int b) { return a * b; }
}
```

---

## 3. toy-project Module

- `pom.xml`: parent = root POM; depends on `calculator-lib`
- `CalculatorResource.java` — main REST resource (replaces `TestResource.java`)
- `CalculatorResourceTest.java` — unit test (replaces `TestResourceTest.java`)
- `CalculatorResourceIT.java` — integration test (replaces `TestResourceIT.java`)

**`CalculatorResource.java`:**

```java
@Path("/calculator")
public class CalculatorResource {

    @Inject
    CalculatorService calculator;

    @GET
    @Path("/add")
    @Produces(MediaType.TEXT_PLAIN)
    public int add(@QueryParam("a") int a, @QueryParam("b") int b) {
        return calculator.add(a, b);
    }

    @GET
    @Path("/subtract")
    @Produces(MediaType.TEXT_PLAIN)
    public int subtract(@QueryParam("a") int a, @QueryParam("b") int b) {
        return calculator.subtract(a, b);
    }

    @GET
    @Path("/multiply")
    @Produces(MediaType.TEXT_PLAIN)
    public int multiply(@QueryParam("a") int a, @QueryParam("b") int b) {
        return calculator.multiply(a, b);
    }
}
```

Endpoints:
- `GET /calculator/add?a=3&b=4` → `7`
- `GET /calculator/subtract?a=10&b=3` → `7`
- `GET /calculator/multiply?a=3&b=4` → `12`

---

## 4. Kubernetes Manifests (`k8s/`)

### `postgres.yaml`
- `Deployment`: `postgres:17`, env vars for `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` (hardcoded dev values — no Secrets needed for showcase)
- `Service`: ClusterIP on port 5432, name `postgres`

### `configmap.yaml`
Key env vars injected into the toy-project pod:
- `QUARKUS_DATASOURCE_JDBC_URL` → `jdbc:postgresql://postgres:5432/devdb`
- `QUARKUS_DATASOURCE_USERNAME` / `QUARKUS_DATASOURCE_PASSWORD`
- `QUARKUS_LAUNCH_DEVMODE=true` — starts the app in dev mode inside the pod
- `QUARKUS_DEVMODE_PASSWORD` — shared secret for the remote dev live-reload handshake
- `QUARKUS_PACKAGE_JAR_TYPE=mutable-jar` — required; allows the remote agent to hot-swap classes

### `toy-project.yaml`
- `Deployment`: uses `toy-project-jvm` image, `imagePullPolicy: Never` (Minikube local registry), envFrom the ConfigMap, exposes ports 8080 (HTTP) and 5005 (remote dev agent)
- `Service`: `NodePort` exposing both ports outside the cluster so the local `quarkus:remote-dev` client can reach the agent

---

## 5. Remote Dev Workflow (the showcase steps)

```bash
# 1. Start Minikube
minikube start

# 2. Point Docker daemon at Minikube's registry
eval $(minikube docker-env)

# 3. Build the mutable JAR
cd toy-project
./mvnw package -Dquarkus.package.jar.type=mutable-jar

# 4. Build the JVM image (inside Minikube's Docker)
docker build -f src/main/docker/Dockerfile.jvm -t toy-project-jvm .

# 5. Deploy to Minikube
cd ..
kubectl apply -f k8s/

# 6. Start remote dev from laptop — changes hot-swap into the running pod
cd toy-project
# Get the NodePort assigned to the toy-project service
NODE_PORT=$(kubectl get svc toy-project -o jsonpath='{.spec.ports[?(@.port==8080)].nodePort}')

./mvnw quarkus:remote-dev \
  -Dquarkus.live-reload.url=http://$(minikube ip):${NODE_PORT} \
  -Dquarkus.live-reload.password=<QUARKUS_DEVMODE_PASSWORD>

# 7. Edit CalculatorService or CalculatorResource → saved changes stream into the pod live
```

The key demo moment: edit `CalculatorService.add()` to return `a + b + 1`, save — the remote dev client recompiles and pushes the delta; the pod picks it up without a redeploy.

---

## 6. Build Commands

The Maven wrapper (`mvnw`) lives in `toy-project/`. Run multi-module builds from the repo root using it:

```bash
# Build all modules (from repo root)
toy-project/mvnw install

# Run toy-project in local dev mode (no Kubernetes)
cd toy-project && ./mvnw quarkus:dev

# Run tests (from repo root)
toy-project/mvnw test
```

The root `pom.xml` imports the Quarkus BOM so both `calculator-lib` and `toy-project` share the same Quarkus version without duplicating it.

---

## 7. Out of Scope

- Secrets management (hardcoded dev credentials are intentional for the showcase)
- Native image builds
- Multiple replicas / horizontal scaling
- CI/CD pipeline
