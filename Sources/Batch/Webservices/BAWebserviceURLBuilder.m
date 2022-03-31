//
//  BAWebserviceURLBuilder.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWebserviceURLBuilder.h>

#import <Batch/BACoreCenter.h>

@implementation BAWebserviceURLBuilder

+ (nullable NSURL *)webserviceURLForShortname:(nonnull NSString *)shortname {
    return [BAWebserviceURLBuilder webserviceURLForHost:[BAWebserviceURLBuilder host]
                                              shortname:shortname
                                                 apiKey:BACoreCenter.instance.configuration.developperKey];
}

+ (nullable NSURL *)webserviceURLForShortname:(nonnull NSString *)shortname apiKey:(nonnull NSString *)apiKey {
    return [BAWebserviceURLBuilder webserviceURLForHost:[BAWebserviceURLBuilder host]
                                              shortname:shortname
                                                 apiKey:apiKey];
}

+ (nullable NSURL *)webserviceURLForHost:(nonnull NSString *)host shortname:(nonnull NSString *)shortname {
    return [BAWebserviceURLBuilder webserviceURLForHost:host
                                              shortname:shortname
                                                 apiKey:BACoreCenter.instance.configuration.developperKey];
}

+ (nullable NSURL *)webserviceURLForHost:(nonnull NSString *)host {
    NSMutableString *urlString = [[NSMutableString alloc] init];

    [urlString appendString:host];
    [urlString appendString:@"/i/"];
    [urlString appendString:BACoreCenter.sdkVersion];

    return [NSURL URLWithString:urlString relativeToURL:nil];
}

+ (nullable NSURL *)webserviceURLForHost:(nonnull NSString *)host
                               shortname:(nonnull NSString *)shortname
                                  apiKey:(nonnull NSString *)apiKey {
    if ([BANullHelper isStringEmpty:apiKey]) {
        [BALogger debugForDomain:@"WebserviceURLBuilder"
                         message:@"Tried to call a webservice with a nil or empty API Key. Aborting."];
        return nil;
    }

    NSMutableString *urlString = [[NSMutableString alloc] init];

    [urlString appendString:host];
    [urlString appendString:@"/i/"];
    [urlString appendString:BACoreCenter.sdkVersion];
    [urlString appendString:@"/"];
    [urlString appendString:shortname];
    [urlString appendString:@"/"];

    NSString *escapedAPIKey =
        [apiKey stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];

    [urlString appendString:escapedAPIKey];

    return [NSURL URLWithString:urlString relativeToURL:nil];
}

+ (NSString *)host {
    return kParametersWebserviceBase;
}

@end
