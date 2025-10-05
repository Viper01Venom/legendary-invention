import ballerina/http;
import ballerinax/mongodb;
import ballerina/kafka;

type Route record {
    string _id;
    string name;
    json schedule;
};

mongodb:Client mongoClient = check new({
    connection: "mongodb://mongo:27017",
    database: "smart_ticketing"
});

listener http:Listener transportListener = new (8082);

// Kafka producer to publish schedule updates
kafka:Producer scheduleProducer = check new({
    bootstrapServers: "kafka:9092"
});

service /transport on transportListener {

    resource function post route(http:Request req) returns http:Response|error {
        Route r = check req.getJsonPayload();
        r._id = "route-" + r.name.replaceAll("\\s+", "-");
        mongodb:Database db = check mongoClient->getDatabase("smart_ticketing");
        mongodb:Collection col = check db->getCollection("routes");
        check col->insert(r);
        return new http:Response("route created");
    }

    resource function post publishSchedule(http:Request req) returns http:Response|error {
        map<any> body = check req.getJsonPayload();
        string routeId = body["routeId"].toString();
        json update = body["update"];
        // publish to Kafka topic schedule.updates
        var sendRes = scheduleProducer->send({
            topic: "schedule.updates",
            value: update.toJsonString()
        });
        if sendRes is error {
            return new http:Response("failed", 500);
        }
        return new http:Response("published");
    }
}
