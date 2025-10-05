import ballerina/http;
import ballerinax/mongodb;
import ballerina/kafka;
import ballerina/log;

type Ticket record {
    string _id;
    string passengerId;
    string routeId;
    string status; // CREATED, PAID, VALIDATED, EXPIRED
    int createdAt;
};

mongodb:Client mongoClient = check new({
    connection: "mongodb://mongo:27017",
    database: "smart_ticketing"
});

listener http:Listener ticketListener = new (8083);

// Kafka producer to request payments
kafka:Producer paymentProducer = check new({
    bootstrapServers: "kafka:9092"
});

// Kafka consumer to receive payment confirmations
listener kafka:Listener paymentsConsumer = new (kafka:DEFAULT_URL, {
    groupId: "payment-confirm-group"
});

service /ticket on ticketListener {

    resource function post create(http:Request req) returns http:Response|error {
        Ticket t = check req.getJsonPayload();
        t._id = "t-" + t.passengerId + "-" + (time:currentTime().unixTimestamp()).toString();
        t.status = "CREATED";
        t.createdAt = time:currentTime().unixTimestamp();
        mongodb:Database db = check mongoClient->getDatabase("smart_ticketing");
        mongodb:Collection col = check db->getCollection("tickets");
        check col->insert(t);

        // publish payment request
        var sendRes = paymentProducer->send({
            topic: "ticket.requests",
            key: t._id,
            value: t.toJsonString()
        });
        if sendRes is error {
            return new http:Response("failed to request payment", 500);
        }
        return new http:Response("ticket created: " + t._id);
    }
}
