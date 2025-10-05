import ballerina/http;
import ballerina/kafka;
import ballerina/log;

listener http:Listener paymentListener = new (8084);

// Kafka consumer listening for ticket.requests to simulate payment request
listener kafka:Listener ticketRequests = new (kafka:DEFAULT_URL, {
    groupId: "payment-service-group"
});

// Kafka producer to publish processed payments
kafka:Producer processedProducer = check new({
    bootstrapServers: "kafka:9092"
});

service /payment on paymentListener {
    resource function get health() returns string {
        return "ok";
    }
}

service on ticketRequests {
    resource function onMessage(kafka:ConsumerMessage msg) returns error? {
        string key = msg.key.toString();
        string value = msg.value.toString();
        log:printInfo("Payment service received ticket request: " + key);
        // Simulate processing delay and success (in real system we'd contact payment gateway)
        // After processing, publish to payments.processed
        var sendRes = processedProducer->send({
            topic: "payments.processed",
            key: key,
            value: "{\"status\":\"SUCCESS\",\"ticketId\":\"" + key + "\"}"
        });
        if sendRes is error {
            log:printError("Failed to publish payment processed: " + sendRes.message());
        }
        return;
    }
}
