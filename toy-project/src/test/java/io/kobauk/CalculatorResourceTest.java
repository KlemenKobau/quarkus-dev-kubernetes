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
