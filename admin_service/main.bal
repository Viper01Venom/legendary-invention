import ballerina/http;
import ballerinax/mongodb;

mongodb:Client mongoClient = check new({
    connection: "mongodb://mongo:27017",
    database: "smart_ticketing"
});

listener http:Listener adminListener = new (8085);

service /admin on adminListener {
    resource function get salesReport() returns http:Response|error {
        mongodb:Database db = check mongoClient->getDatabase("Smart_Ticket");
        mongodb:Collection col = check db->getCollection("tickets");
        var cursor = col->find({});
        int total = 0;
        json[] docs = [];
        if cursor is stream<json, error> {
            json? d;
            while (true) {
                d = cursor.next();
                if d is json {
                    docs.push(d);
                    total += 1;
                } else {
                    break;
                }
            }
        }
        var resp = new http:Response();
        resp.setJsonPayload({ "totalTickets": total, "tickets": docs });
        return resp;
    }
}

