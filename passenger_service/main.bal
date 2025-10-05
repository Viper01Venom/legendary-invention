import ballerina/http;
import ballerinax/mongodb;
import ballerina/log;

type Passenger record {
    string _id; // use as MongoDB _id
    string name;
    string email;
    string password;
};

mongodb:Client mongoClient = check new({
    connection: "mongodb://mongo:27017",
    database: "smart_ticketing"
});

listener http:Listener passengerListener = new (8081);

service /passenger on passengerListener {

    resource function post register(http:Request req) returns http:Response|error {
        Passenger p = check req.getJsonPayload();
        // generate id
        p._id = "p-" + p.email.replaceAll("[^a-zA-Z0-9]", "_");
        mongodb:Database db = check mongoClient->getDatabase("smart_ticketing");
        mongodb:Collection col = check db->getCollection("passengers");
        check col->insert(p);
        return new http:Response("registered:" + p._id);
    }

    resource function post login(http:Request req) returns http:Response|error {
        map<any> creds = check req.getJsonPayload();
        string email = creds["email"].toString();
        string password = creds["password"].toString();

        mongodb:Database db = check mongoClient->getDatabase("smart_ticketing");
        mongodb:Collection col = check db->getCollection("passengers");
        var res = col->find({ "email": email, "password": password });
        if res is stream<json, error> {
            json? doc = check res.next();
            if doc is json {
                return new http:Response("login ok");
            }
        }
        return new http:Response("invalid credentials", 401);
    }

    resource function get tickets(http:Request req, string passengerId) returns http:Response|error {
        // simple proxy to ticketing service DB - here we just query tickets collection
        mongodb:Database db = check mongoClient->getDatabase("smart_ticketing");
        mongodb:Collection col = check db->getCollection("tickets");
        var cursor = col->find({ "passengerId": passengerId }) ;
        json[] arr = [];
        if cursor is stream<json, error> {
            json? doc;
            while (true) {
                doc = cursor.next();
                if doc is json {
                    arr.push(doc);
                } else {
                    break;
                }
            }
        }
        var resp = new http:Response();
        resp.setJsonPayload(arr);
        return resp;
    }
}
