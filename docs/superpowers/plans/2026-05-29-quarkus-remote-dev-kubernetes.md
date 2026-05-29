# Quarkus Remote Dev in Kubernetes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a multi-module Maven project (calculator-lib + toy-project) with Kubernetes manifests that showcase Quarkus remote development mode running live inside Minikube.

**Architecture:** A root parent POM ties together `calculator-lib` (plain JAR with a CDI `CalculatorService`) and `toy-project` (Quarkus app that injects and exposes `CalculatorService` via REST). Kubernetes manifests in `k8s/` deploy PostgreSQL and the toy-project with remote dev mode enabled, so local edits hot-swap into the running pod without a redeploy.

**Tech Stack:** Quarkus 3.35.4, Java 25, Jakarta REST, Quarkus ARC (CDI), Maven multi-module, Minikube, kubectl, Docker

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `pom.xml` | Root parent POM, declares both modules, imports Quarkus BOM |
| Create | `calculator-lib/pom.xml` | Plain JAR module, `quarkus-arc` provided scope |
| Create | `calculator-lib/src/main/java/io/kobauk/CalculatorService.java` | CDI bean with add/subtract/multiply |
| Modify | `toy-project/pom.xml` | Add parent reference + calculator-lib dependency |
| Create | `toy-project/src/main/java/io/kobauk/CalculatorResource.java` | REST resource delegating to CalculatorService |
| Delete | `toy-project/src/main/java/io/kobauk/TestResource.java` | Replaced by CalculatorResource |
| Create | `toy-project/src/test/java/io/kobauk/CalculatorResourceTest.java` | @QuarkusTest for all three endpoints |
| Create | `toy-project/src/test/java/io/kobauk/CalculatorResourceIT.java` | @QuarkusIntegrationTest extending unit test |
| Delete | `toy-project/src/test/java/io/kobauk/TestResourceTest.java` | Replaced by CalculatorResourceTest |
| Delete | `toy-project/src/test/java/io/kobauk/TestResourceIT.java` | Replaced by CalculatorResourceIT |
| Create | `k8s/postgres.yaml` | PostgreSQL Deployment + ClusterIP Service |
| Create | `k8s/configmap.yaml` | App config + remote dev env vars |
| Create | `k8s/toy-project.yaml` | App Deployment + NodePort Service |
| Update | `CLAUDE.md` | Update commands section for multi-module layout |

---

## Task 1: Root Parent POM

**Files:**
- Create: `pom.xml`

- [ ] **Step 1: Create the root parent POM**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>io.kobauk</groupId>
    <artifactId>quarkus-dev-kubernetes</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <properties>
        <maven.compiler.release>25</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <quarkus.platform.group-id>io.quarkus.platform</quarkus.platform.group-id>
        <quarkus.platform.artifact-id>quarkus-bom</quarkus.platform.artifact-id>
        <quarkus.platform.version>3.35.4</quarkus.platform.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>${quarkus.platform.group-id}</groupId>
                <artifactId>${quarkus.platform.artifact-id}</artifactId>
                <version>${quarkus.platform.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <modules>
        <module>calculator-lib</module>
        <module>toy-project</module>
    </modules>
</project>
```

- [ ] **Step 2: Verify the file parses**

```bash
toy-project/mvnw help:evaluate -Dexpression=project.artifactId -q -f pom.xml
```

Expected output: `quarkus-dev-kubernetes`

- [ ] **Step 3: Commit**

```bash
git add pom.xml
git commit -m "build: add root parent POM for multi-module layout"
```

---

## Task 2: calculator-lib Module

**Files:**
- Create: `calculator-lib/pom.xml`
- Create: `calculator-lib/src/main/java/io/kobauk/CalculatorService.java`

- [ ] **Step 1: Create the calculator-lib directory structure**

```bash
mkdir -p calculator-lib/src/main/java/io/kobauk
```

- [ ] **Step 2: Create `calculator-lib/pom.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>io.kobauk</groupId>
        <artifactId>quarkus-dev-kubernetes</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>calculator-lib</artifactId>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-arc</artifactId>
            <scope>provided</scope>
        </dependency>
    </dependencies>
</project>
```

- [ ] **Step 3: Create `calculator-lib/src/main/java/io/kobauk/CalculatorService.java`**

```java
package io.kobauk;

import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class CalculatorService {

    public int add(int a, int b) {
        return a + b;
    }

    public int subtract(int a, int b) {
        return a - b;
    }

    public int multiply(int a, int b) {
        return a * b;
    }
}
```

- [ ] **Step 4: Verify the module compiles**

```bash
toy-project/mvnw compile -pl calculator-lib
```

Expected: `BUILD SUCCESS`

- [ ] **Step 5: Commit**

```bash
git add calculator-lib/
git commit -m "feat: add calculator-lib module with CalculatorService"
```

---

## Task 3: Update toy-project POM

**Files:**
- Modify: `toy-project/pom.xml`

- [ ] **Step 1: Add the parent reference and calculator-lib dependency to `toy-project/pom.xml`**

Add a `<parent>` block right after `<modelVersion>`:

```xml
    <parent>
        <groupId>io.kobauk</groupId>
        <artifactId>quarkus-dev-kubernetes</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>
```

Remove the duplicate `<groupId>io.kobauk</groupId>` and `<version>1.0.0-SNAPSHOT</version>` lines that are now inherited from the parent (keep `<artifactId>toy-project</artifactId>` and `<packaging>quarkus</packaging>`).

Add this dependency inside `<dependencies>`:

```xml
        <dependency>
            <groupId>io.kobauk</groupId>
            <artifactId>calculator-lib</artifactId>
            <version>${project.version}</version>
        </dependency>
```

Remove the duplicate `<dependencyManagement>` block that imports the Quarkus BOM — it is now inherited from the root POM.

- [ ] **Step 2: Verify the full multi-module build compiles**

```bash
toy-project/mvnw install -DskipTests
```

Expected: `BUILD SUCCESS` with both `calculator-lib` and `toy-project` listed.

- [ ] **Step 3: Commit**

```bash
git add toy-project/pom.xml
git commit -m "build: wire toy-project into root parent, add calculator-lib dependency"
```

---

## Task 4: CalculatorResource and Tests

**Files:**
- Create: `toy-project/src/main/java/io/kobauk/CalculatorResource.java`
- Delete: `toy-project/src/main/java/io/kobauk/TestResource.java`
- Create: `toy-project/src/test/java/io/kobauk/CalculatorResourceTest.java`
- Delete: `toy-project/src/test/java/io/kobauk/TestResourceTest.java`
- Create: `toy-project/src/test/java/io/kobauk/CalculatorResourceIT.java`
- Delete: `toy-project/src/test/java/io/kobauk/TestResourceIT.java`

- [ ] **Step 1: Write the failing tests first**

Create `toy-project/src/test/java/io/kobauk/CalculatorResourceTest.java`:

```java
package io.kobauk;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
class CalculatorResourceTest {

    @Test
    void testAdd() {
        given()
            .queryParam("a", 3)
            .queryParam("b", 4)
            .when().get("/calculator/add")
            .then()
            .statusCode(200)
            .body(is("7"));
    }

    @Test
    void testSubtract() {
        given()
            .queryParam("a", 10)
            .queryParam("b", 3)
            .when().get("/calculator/subtract")
            .then()
            .statusCode(200)
            .body(is("7"));
    }

    @Test
    void testMultiply() {
        given()
            .queryParam("a", 3)
            .queryParam("b", 4)
            .when().get("/calculator/multiply")
            .then()
            .statusCode(200)
            .body(is("12"));
    }
}
```

- [ ] **Step 2: Delete the old test files**

```bash
rm toy-project/src/test/java/io/kobauk/TestResourceTest.java
rm toy-project/src/test/java/io/kobauk/TestResourceIT.java
```

- [ ] **Step 3: Run the tests to verify they fail (CalculatorResource doesn't exist yet)**

```bash
cd toy-project && ./mvnw test -Dtest=CalculatorResourceTest
```

Expected: FAIL — `404 Not Found` or compilation error because `/calculator/add` does not exist.

- [ ] **Step 4: Create `toy-project/src/main/java/io/kobauk/CalculatorResource.java`**

```java
package io.kobauk;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

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

- [ ] **Step 5: Delete the old resource**

```bash
rm toy-project/src/main/java/io/kobauk/TestResource.java
```

- [ ] **Step 6: Run the tests to verify they pass**

```bash
cd toy-project && ./mvnw test -Dtest=CalculatorResourceTest
```

Expected: `Tests run: 3, Failures: 0, Errors: 0` — `BUILD SUCCESS`

- [ ] **Step 7: Create the integration test**

Create `toy-project/src/test/java/io/kobauk/CalculatorResourceIT.java`:

```java
package io.kobauk;

import io.quarkus.test.junit.QuarkusIntegrationTest;

@QuarkusIntegrationTest
class CalculatorResourceIT extends CalculatorResourceTest {
    // Runs the same tests against the packaged application.
}
```

- [ ] **Step 8: Commit**

```bash
git add toy-project/src/main/java/io/kobauk/CalculatorResource.java \
        toy-project/src/test/java/io/kobauk/CalculatorResourceTest.java \
        toy-project/src/test/java/io/kobauk/CalculatorResourceIT.java
git rm toy-project/src/main/java/io/kobauk/TestResource.java \
       toy-project/src/test/java/io/kobauk/TestResourceTest.java \
       toy-project/src/test/java/io/kobauk/TestResourceIT.java
git commit -m "feat: replace TestResource with CalculatorResource delegating to CalculatorService"
```

---

## Task 5: Kubernetes Manifests

**Files:**
- Create: `k8s/postgres.yaml`
- Create: `k8s/configmap.yaml`
- Create: `k8s/toy-project.yaml`

- [ ] **Step 1: Create `k8s/postgres.yaml`**

```bash
mkdir -p k8s
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:17
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: devdb
            - name: POSTGRES_USER
              value: devuser
            - name: POSTGRES_PASSWORD
              value: devpassword
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
```

- [ ] **Step 2: Create `k8s/configmap.yaml`**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: toy-project-config
data:
  QUARKUS_DATASOURCE_JDBC_URL: "jdbc:postgresql://postgres:5432/devdb"
  QUARKUS_DATASOURCE_USERNAME: "devuser"
  QUARKUS_DATASOURCE_PASSWORD: "devpassword"
  QUARKUS_LAUNCH_DEVMODE: "true"
  QUARKUS_DEVMODE_PASSWORD: "devpassword"
  QUARKUS_PACKAGE_JAR_TYPE: "mutable-jar"
```

- [ ] **Step 3: Create `k8s/toy-project.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: toy-project
spec:
  replicas: 1
  selector:
    matchLabels:
      app: toy-project
  template:
    metadata:
      labels:
        app: toy-project
    spec:
      containers:
        - name: toy-project
          image: toy-project-jvm
          imagePullPolicy: Never
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 5005
              name: remote-dev
          envFrom:
            - configMapRef:
                name: toy-project-config
---
apiVersion: v1
kind: Service
metadata:
  name: toy-project
spec:
  type: NodePort
  selector:
    app: toy-project
  ports:
    - name: http
      port: 8080
      targetPort: 8080
    - name: remote-dev
      port: 5005
      targetPort: 5005
```

- [ ] **Step 4: Validate manifest syntax**

```bash
kubectl apply --dry-run=client -f k8s/
```

Expected: three lines of `... configured (dry run)` with no errors.

- [ ] **Step 5: Commit**

```bash
git add k8s/
git commit -m "feat: add Kubernetes manifests for postgres and toy-project with remote dev"
```

---

## Task 6: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the Commands section in `CLAUDE.md`**

Replace the existing commands block with the multi-module equivalents. The Maven wrapper now lives in `toy-project/` but is invoked from the repo root for multi-module operations:

```markdown
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

# Build mutable JVM JAR (required for remote dev mode)
cd toy-project && ./mvnw package -Dquarkus.package.jar.type=mutable-jar

# Build native executable (requires Docker)
cd toy-project && ./mvnw package -Dnative -Dquarkus.native.container-build=true
```
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md commands for multi-module Maven layout"
```

---

## Task 7: End-to-End Smoke Test

This task verifies the full remote dev showcase works in Minikube. It is a manual checklist — no automated test can cover the live hot-swap loop.

- [ ] **Step 1: Start Minikube and point Docker at its registry**

```bash
minikube start
eval $(minikube docker-env)
```

Expected: `minikube status` shows `Running`.

- [ ] **Step 2: Build the mutable JAR and JVM image**

```bash
cd toy-project
./mvnw package -Dquarkus.package.jar.type=mutable-jar
docker build -f src/main/docker/Dockerfile.jvm -t toy-project-jvm .
cd ..
```

Expected: image `toy-project-jvm` appears in `docker images`.

- [ ] **Step 3: Deploy to Minikube**

```bash
kubectl apply -f k8s/
kubectl rollout status deployment/postgres
kubectl rollout status deployment/toy-project
```

Expected: both deployments reach `successfully rolled out`.

- [ ] **Step 4: Verify the REST endpoint responds**

```bash
NODE_PORT=$(kubectl get svc toy-project -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
curl "http://$(minikube ip):${NODE_PORT}/calculator/add?a=3&b=4"
```

Expected: `7`

- [ ] **Step 5: Start remote dev from the laptop**

```bash
cd toy-project
./mvnw quarkus:remote-dev \
  -Dquarkus.live-reload.url=http://$(minikube ip):${NODE_PORT} \
  -Dquarkus.live-reload.password=devpassword
```

Expected: `Connected to remote server` in the console output.

- [ ] **Step 6: Demonstrate the hot-swap**

Edit `calculator-lib/src/main/java/io/kobauk/CalculatorService.java` — change `add` to return `a + b + 100`. Save the file. The remote dev client will recompile and push the delta.

```bash
# In a separate terminal (NODE_PORT already set):
curl "http://$(minikube ip):${NODE_PORT}/calculator/add?a=3&b=4"
```

Expected: `107` — no redeploy, no restart.

Revert the change to restore correct behaviour.

- [ ] **Step 7: Teardown**

```bash
kubectl delete -f k8s/
eval $(minikube docker-env -u)
```
