#  Batch Webservice Clients

Batch's webservice architecture is made of many parts, each stopping at an abstraction level.

The chain looks like this, the lower level being on the left.
```
Webservice --> JSON Webservice --> Query Webservice -> Query Service
                              |_> GET Webservice
```

Nothing starts a client itself: `-start` is `NS_UNAVAILABLE` on BAWebserviceClient. A request is sent by building the client and handing it to `[BAWebserviceClientExecutor.sharedInstance addClient:]`.

## Core
This is the "core" webservice code, and where an outgoing call to a Batch backend belongs. It is not the only way the SDK reaches the network: `BAMSGImageDownloader` drives its own `NSURLSession` for message assets, outside this stack entirely.

- BAConnection is a relatively thin wrapper over NSURLSession, abstracting it and adding error handling. It takes a delegate to communicate success and error. It is also where ciphering happens: it runs the cryptor factory the client handed it over the outbound body and over the server's reply
- BAWebserviceClient is an NSOperation. It collects the URL, GET query parameters, POST body and headers from methods its subclasses override (`queryParameters`, `requestBody:`, `requestHeaders`, `cryptorFactory`), appends the query parameters to the URL, and configures the connection with the result. It also acts as the BAConnectionDelegate and forwards every callback to its own delegate
- BAWebserviceJsonClient is the JSON layer: subclasses override `requestBodyDictionary` or `requestBodyArray`, and it serializes whichever one is provided — array first, dictionary as a fallback
- BAWebserviceClientExecutor handles executing the clients, limits the number of concurrent requests (`kWebserviceClientExecutorMaxConcurrency`, defined in `sdk/Batch/Supporting Files/Defined.h`), and keeps a strong reference to the clients while they're working — it owns an NSOperationQueue and the clients are the operations it enqueues

## Crypto
The webservice client payload and server answer are encrypted. These classes handle that: `BAWebserviceCryptorFactory` vends the outbound cryptor, the inbound cryptor and the HMAC provider, and BAConnection applies them. A client that needs a different scheme overrides `cryptorFactory`; returning nil sends and reads plaintext.

## Query
Batch's query webservices use a format carrying device identifiers and multiple queries in a single HTTP request.
Think of a query like some kind of question: you can put multiple in a single one. 
The server is expected to reply to all of the queries (called "responses"), and the SDK will match the sent queries with their responses using a randomly generated ID (`BAWSQuery` assigns itself a UUID at init). A query with no matching response fails the whole request, not just that query.

Not every client goes through this: some build straight on BAWebserviceJsonClient or BAGETWebserviceClient instead — see the `JSON Services implementations/` folder, and the Inbox and Metrics modules.

These classes handle most of the boilerplade (collecting the identifiers that are in all query webservices through `BAQueryWebserviceIdentifiersProviding`, aggregating the queries, instanciating the responses, etc...)
They also define a Datasource and Delegate protocols, so that the QueryWebserviceClient can easily collect data from multiple sources in the most lightweight way possible, and especially without having to override this class

## Query Services

A query service, usually simply called a "Service" is basically the implementation of one or multiple couples of BAQueryWebserviceClientDatasource/Delegate. 
They are called "Services" to make the class name shorter, and essentially hide their transport: from the SDK's point of view, they are services that it can use to access backend resources. 
Them using a Query Webservice transport is nothing but an implementation detail: the caller instanciates a `BAQueryWebserviceClient` with the datasource, and the datasource is a plain object.

The datasource supplies the URL (built with `BAWebserviceURLBuilder webserviceURLForHost:shortname:`), the long and short request identifiers, the queries to send, and turns a raw response back into a Response object. The delegate — which reports failure and the parsed responses — is optional: a service that does not care about the outcome passes nil, as the start webservice does. Note that the client holds its delegate strongly, so a delegate lives at least as long as the request.

## Queries and Responses

The Query Services datasources have to create Query objects when sending their requests and map them to Response objects
We rely on classes to strongly type both query and responses. These are basically the models and json serializer/deserializers for the query and response content. They live next to the services, in the `Query Models` and `Response Models` folders: a query serializes itself through `objectToSend`, a response parses itself in `initWithResponse:`.
