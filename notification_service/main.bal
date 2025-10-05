import ballerina/kafka;
import ballerina/log;
import ballerinax/mongodb;

mongodb:Client mongoClient = check new({
    connection: "mongodb://mongo:27017",
    database: "smart_ticketing"
});

// Listen to schedule.updates
listener kafka:Listener notifConsumer = new (kafka:DEFAULT_URL, {
    groupId: "notification-group"
});

service on notifConsumer {

    resource function onMessage(kafka:ConsumerMessage msg) returns error? {
        string topic = msg.topic;
        string value = msg.value.toString();
        log:printInfo("Notification service received on topic " + topic + ": " + value);
        // Here we would push notifications to users (email/real-time). For demo: store to notifications collection
        mongodb:Database db = check mongoClient->getDatabase("smart_ticketing");
        mongodb:Collection col = check db->getCollection("notifications");
        json doc = { "topic": topic, "payload": value, "ts": time:currentTime().unixTimestamp() };
        check col->insert(doc);
        return;
    }
}

