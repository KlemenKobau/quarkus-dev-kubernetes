package io.kobauk;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

@ApplicationScoped
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
