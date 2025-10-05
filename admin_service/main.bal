import ballerina/http;
import ballerina/log;

// Simple HTTP service skeleton for <SERVICE_NAME>
// Replace with your real code (Kafka, DB clients, endpoints...).

listener http:Listener backendEP = new(9090);

service / on backendEP {

    // GET /health
    resource function get health(http:Caller caller, http:Request req) returns error? {
        json resp = { status: "ok", service: "<SERVICE_NAME>" };
        check caller->respond(resp);
    }

    // Example endpoint, replace with your actual handlers
    resource function post action(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        log:printInfo("<<SERVICE>> Received: " + payload.toString());
        json resp = { result: "accepted", service: "<SERVICE_NAME>" };
        check caller->respond(resp);
    }
}

