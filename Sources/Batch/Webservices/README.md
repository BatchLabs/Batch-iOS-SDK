#  Batch Webservice Clients

Batch's webservice architecture is made of many parts, each stopping at an abstraction level.

The chain looks like this, the lower level being on the left.
```
Webservice --> Query Webservice -> Query Service
           |_> GET Webservice
```

## Core
This is the "core" webservice code that should be used for **all** outgoing network calls.

- BAConnection is a relatively thin wrapper over NSURLSession, abstracting it and adding error handling. It takes a delegate to communicate success and error
- BAWebserviceClient will collect the URL, GET query parameters, POST data if applicable, and headers. It is responsible to configure the connection, serialize the post data as json, encrypt it and finally send the request.
- BAWebserviceClientExecutor handles executing the clients, limits the number of concurrent requests, and keeps a strong reference to the clients while they're working

## Crypto
The webservice client payload and server answer are encrypted. These classes handle that

## Query
Most Batch webservices (with the exception of the Inbox API) use a "query" based format, with device identifiers and multiple queries.
Think of a query like some kind of question: you can put multiple in a single HTTP request. 
The server is expected to reply to all of the queries (called "responses"), and the SDK will match the sent queries with their responses using a randomly generated ID.

These classes handle most of the boilerplade (collecting the identifiers that are in all query webservices, aggregate the queries, instanciate the responses, etc...)
They also define a Datasource and Delegate protocols, so that the QueryWebserviceClient can easily collect data from multiple sources in the most lightweight way possible, and especially without having to override this class

## Query Services

A query service, usually simply called a "Service" is basically the implementation of one or multiple couples of BAQueryWebserviceClientDatasource/Delegate. 
They are called "Services" to make the class name shorter, and essentially hide their inheritence: from the SDK's point of view, they are services that it can use to access backend resources. 
Them using a Query Webservice transport is nothing but an implementation detail.

## Queries and Responses

The Query Services datasources have to create Query objects when sending their requests and map them to Response objects
We rely on classes to strongly type both query and responses. These are basically the models and json serializer/deserializers for the query and response content.
