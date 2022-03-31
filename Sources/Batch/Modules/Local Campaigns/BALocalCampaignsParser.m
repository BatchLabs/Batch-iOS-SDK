//
//  BALocalCampaignsParser.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignsParser.h>

#import <Batch/BAEventTrigger.h>
#import <Batch/BANextSessionTrigger.h>
#import <Batch/BATJsonDictionary.h>

#import <Batch/BALocalCampaignLandingOutput.h>
#import <Batch/BALocalCampaignOutputProtocol.h>

#import <Batch/BATZAwareDate.h>

@implementation BALocalCampaignsParser

+ (NSArray<BALocalCampaign *> *)parseCampaigns:(NSDictionary *)rawJson
                                outPersistable:(NSDictionary **)persist
                                         error:(NSError **)error {
    NSMutableArray<NSObject *> *persistCampaigns = [NSMutableArray new];
    NSMutableArray<BALocalCampaign *> *parsedCampaigns = [NSMutableArray new];

    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson
                                          errorDomain:@"com.batch.module.localcampaigns.parser.error"];

    NSDictionary *serverError = [json objectForKey:@"error" kindOfClass:[NSDictionary class] fallback:nil];
    if (serverError != nil) {
        NSDictionary *errorDetails = [BALocalCampaignsParser parseServerError:serverError];
        if (error) {
            if (errorDetails != nil) {
                *error = [BALocalCampaignsParser
                    genericParsingErrorForReason:
                        [NSString stringWithFormat:@"Server returned an error. Code: %@, Message: '%@'",
                                                   errorDetails[@"code"], errorDetails[@"message"]]];
            } else {
                *error = [BALocalCampaignsParser genericParsingErrorForReason:@"Unknown server error"];
            }
        }
        return nil;
    }

    NSError *outErr = nil;

    NSArray *rawJsonContents = [json objectForKey:@"campaigns" kindOfClass:[NSArray class] allowNil:YES error:&outErr];
    if (rawJsonContents == nil && outErr) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    for (NSObject *rawJsonContent in rawJsonContents) {
        if (![rawJsonContent isKindOfClass:[NSDictionary class]]) {
            [BALogger errorForDomain:@"Local Campaigns"
                             message:@"A non-JSON Object was found in the 'contents' array of local campaigns (type: "
                                     @"%@). Ignoring.",
                                     NSStringFromClass([rawJsonContent class])];
            continue;
        }

        BALocalCampaign *parsedCampaign = [self parseCampaign:(NSDictionary *)rawJsonContent error:&outErr];
        if (parsedCampaign == nil) {
            [BALogger errorForDomain:@"Local Campaigns"
                             message:@"An error occurred while parsing a local campaign: %@. Ignoring.",
                                     [outErr localizedDescription]];
            continue;
        }
        [parsedCampaigns addObject:parsedCampaign];

        if ([parsedCampaign persist]) {
            [persistCampaigns addObject:rawJsonContent];
        }
    }

    [BALogger debugForDomain:@"Local Campaigns"
                     message:@"Successfully parsed %lu campaigns", (unsigned long)[parsedCampaigns count]];

    if (persist != nil) {
        [BALogger debugForDomain:@"Local Campaigns"
                         message:@"Persisting %lu campaigns", (unsigned long)[persistCampaigns count]];
        *persist = @{@"campaigns" : persistCampaigns};
    }
    return parsedCampaigns;
}

+ (BALocalCampaign *)parseCampaign:(NSDictionary *)rawJson error:(NSError **)error {
    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson
                                          errorDomain:@"com.batch.module.localcampaigns.parser.error.campaign"];
    BALocalCampaign *campaign = [BALocalCampaign new];

    NSError *outErr = nil;

    campaign.campaignID = [json objectForKey:@"campaignId" kindOfClass:[NSString class] allowNil:NO error:&outErr];
    if (campaign.campaignID == nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    campaign.publicToken = [json objectForKey:@"campaignToken" kindOfClass:[NSString class] fallback:nil];

    campaign.devTrackingIdentifier = [json objectForKey:@"devTrackingId"
                                            kindOfClass:[NSString class]
                                               allowNil:YES
                                                  error:&outErr];
    if (campaign.devTrackingIdentifier == nil && outErr != nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    campaign.eventData = [json objectForKey:@"eventData" kindOfClass:[NSDictionary class] allowNil:YES error:&outErr];
    if (campaign.eventData == nil && outErr != nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    campaign.minimumAPILevel = [[json objectForKey:@"minimumApiLevel" kindOfClass:[NSNumber class]
                                          fallback:@0] integerValue];
    if (campaign.minimumAPILevel < 0) {
        if (error) {
            *error = [self genericParsingErrorForReason:@"If specified, minimumApiLevel must be >= 0"];
        }
        return nil;
    }

    NSDictionary *startDateJson = [json objectForKey:@"startDate"
                                         kindOfClass:[NSDictionary class]
                                            allowNil:YES
                                               error:&outErr];
    if (startDateJson != nil) {
        campaign.startDate = [self parseDate:startDateJson error:nil];
    }

    NSDictionary *endDateJson = [json objectForKey:@"endDate" kindOfClass:[NSDictionary class] allowNil:YES error:nil];
    if (endDateJson != nil) {
        // TODO check if end date < start date and fail
        campaign.endDate = [self parseDate:endDateJson error:nil];
    }

    campaign.priority = [[json objectForKey:@"priority" kindOfClass:[NSNumber class] fallback:@0] integerValue];

    campaign.capping = [[json objectForKey:@"capping" kindOfClass:[NSNumber class] fallback:@0] integerValue];

    campaign.minimumDisplayInterval = [[json objectForKey:@"minDisplayInterval"
                                              kindOfClass:[NSNumber class]
                                                 fallback:@(60)] integerValue];

    campaign.persist = [[json objectForKey:@"persist" kindOfClass:[NSNumber class] fallback:@(YES)] boolValue];

    campaign.customPayload = [json objectForKey:@"customPayload"
                                    kindOfClass:[NSDictionary class]
                                       allowNil:YES
                                          error:&outErr];
    if (campaign.customPayload == nil && outErr != nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    campaign.requiresJustInTimeSync = [[json objectForKey:@"requireJIT" kindOfClass:[NSNumber class]
                                                 fallback:@(NO)] boolValue];

    NSArray *triggersJSON = [json objectForKey:@"triggers" kindOfClass:[NSArray class] allowNil:NO error:&outErr];
    if (triggersJSON == nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    campaign.triggers = [self parseTriggers:triggersJSON error:&outErr];
    if (campaign.triggers == nil && outErr != nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    NSDictionary *outputJSON = [json objectForKey:@"output" kindOfClass:[NSDictionary class] allowNil:NO error:&outErr];
    if (outputJSON == nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    campaign.output = [self parseOutput:outputJSON error:&outErr];
    if (campaign.output == nil && outErr != nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    return campaign;
}

+ (NSArray<id<BALocalCampaignTriggerProtocol>> *)parseTriggers:(NSArray *)rawJson error:(NSError **)error {
    NSMutableArray *triggers = [NSMutableArray arrayWithCapacity:[rawJson count]];

    for (NSDictionary *jsonTrigger in rawJson) {
        if (![jsonTrigger isKindOfClass:[NSDictionary class]]) {
            [BALogger debugForDomain:@"Local Campaigns" message:@"Trigger is not a NSDictionary, skipping"];
            continue;
        }

        NSError *err = nil;
        id<BALocalCampaignTriggerProtocol> parsedTrigger = [self parseTrigger:jsonTrigger error:&err];
        if (parsedTrigger == nil) {
            [BALogger debugForDomain:@"Local Campaigns"
                             message:@"Could not parse trigger, skipping. Reason: %@",
                                     err ? err.localizedDescription : @"Unknown error"];
            continue;
        }
        [triggers addObject:parsedTrigger];
    }

    if ([triggers count] == 0) {
        if (error) {
            *error = [self genericParsingErrorForReason:@"Could not find any understandable trigger"];
        }
        return nil;
    }

    if (error) {
        *error = nil;
    }
    return triggers;
}

+ (BALocalCampaignsGlobalCappings *)parseCappings:(NSDictionary *)rawJson outPersistable:(NSDictionary **)persist {
    BALocalCampaignsGlobalCappings *cappings = [BALocalCampaignsGlobalCappings new];

    NSDictionary *json = [rawJson objectForKey:@"cappings"];

    if (json != nil && [json isKindOfClass:[NSDictionary class]]) {
        BATJsonDictionary *jsonCappings =
            [[BATJsonDictionary alloc] initWithDictionary:json
                                              errorDomain:@"com.batch.module.localcampaigns.parser.cappings"];

        cappings.session = [jsonCappings objectForKey:@"session" kindOfClass:[NSNumber class] fallback:nil];

        NSArray *jsonTimeBasedCappings = [jsonCappings objectForKey:@"time" kindOfClass:[NSArray class] fallback:nil];

        if (jsonTimeBasedCappings != nil) {
            NSMutableArray<BALocalCampaignsTimeBasedCapping *> *parsedTimeBasedCappings = [NSMutableArray new];

            for (NSObject *jsonTimeBasedCapping in jsonTimeBasedCappings) {
                BALocalCampaignsTimeBasedCapping *timeBasedCapping =
                    [self parseTimeBasedCapping:(NSDictionary *)jsonTimeBasedCapping];
                if (timeBasedCapping != nil && timeBasedCapping.duration != nil && timeBasedCapping.views != nil) {
                    [parsedTimeBasedCappings addObject:timeBasedCapping];
                }
            }
            if ([parsedTimeBasedCappings count] > 0) {
                cappings.timeBasedCappings = parsedTimeBasedCappings;
            }
        }
        if (persist != nil) {
            *persist = @{@"cappings" : json};
        }
        return cappings;
    }
    return nil;
}

+ (BALocalCampaignsTimeBasedCapping *)parseTimeBasedCapping:(NSDictionary *)rawJson {
    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson
                                          errorDomain:@"com.batch.module.localcampaigns.parser.timebasedcapping"];
    BALocalCampaignsTimeBasedCapping *timeBasedCapping = [BALocalCampaignsTimeBasedCapping new];

    timeBasedCapping.views = [json objectForKey:@"views" kindOfClass:[NSNumber class] fallback:nil];
    if (timeBasedCapping.views.intValue == 0) {
        timeBasedCapping.views = nil;
    }
    timeBasedCapping.duration = [json objectForKey:@"duration" kindOfClass:[NSNumber class] fallback:nil];
    if (timeBasedCapping.duration.intValue == 0) {
        timeBasedCapping.duration = nil;
    }
    return timeBasedCapping;
}

+ (id<BALocalCampaignTriggerProtocol>)parseTrigger:(NSDictionary *)rawJson error:(NSError **)error {
    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson
                                          errorDomain:@"com.batch.module.inapp.parser.error.trigger"];

    NSError *outErr = nil;

    NSString *type = [[json objectForKey:@"type" kindOfClass:[NSString class] allowNil:NO
                                   error:&outErr] uppercaseString];
    if (type == nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    if ([type length] == 0) {
        if (error) {
            *error = [self genericParsingErrorForReason:@"Trigger type must not be empty"];
        }
        return nil;
    }

    if ([@"NOW" isEqualToString:type] || [@"NEXT_SESSION" isEqualToString:type]) {
        if (error) {
            *error = nil;
        }
        // Workaround to handle deprecated NOW trigger as NEXT_SESSION
        return [BANextSessionTrigger new];
    } else if ([@"EVENT" isEqualToString:type]) {
        NSString *eventName = [[json objectForKey:@"event" kindOfClass:[NSString class] allowNil:NO
                                            error:&outErr] uppercaseString];
        if (eventName == nil) {
            if (error) {
                *error = outErr;
            }
            return nil;
        }

        NSString *label = [json objectForKey:@"label" kindOfClass:[NSString class] fallback:nil];
        return [BAEventTrigger triggerWithName:eventName label:label];
    }

    if (error) {
        *error = [self genericParsingErrorForReason:@"Unknown trigger type"];
    }
    return nil;
}

+ (id<BALocalCampaignOutputProtocol>)parseOutput:(NSDictionary *)rawJson error:(NSError **)error {
    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson
                                          errorDomain:@"com.batch.module.inapp.parser.error.output"];

    NSError *outErr = nil;

    NSString *type = [[json objectForKey:@"type" kindOfClass:[NSString class] allowNil:NO
                                   error:&outErr] uppercaseString];
    if (type == nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }

    if ([type length] == 0) {
        if (error) {
            *error = [self genericParsingErrorForReason:@"Output type must not be empty"];
        }
        return nil;
    }

    if ([@"LANDING" isEqualToString:type]) {
        NSDictionary *payload = [json objectForKey:@"payload"
                                       kindOfClass:[NSDictionary class]
                                          allowNil:NO
                                             error:&outErr];
        if (payload == nil) {
            if (error) {
                *error = outErr;
            }
            return nil;
        }

        BALocalCampaignLandingOutput *output = [[BALocalCampaignLandingOutput alloc] initWithPayload:payload
                                                                                               error:&outErr];
        if (output == nil) {
            if (error) {
                *error = outErr;
            }
            return nil;
        }
        return output;
    }

    if (error) {
        *error = [self genericParsingErrorForReason:@"Unknown output type"];
    }
    return nil;
}

+ (NSDictionary<NSString *, NSObject *> *)parseServerError:(NSDictionary *)rawJson {
    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson
                                          errorDomain:@"com.batch.module.inapp.parser.error.servererror"];

    return @{
        @"code" : [json objectForKey:@"code" kindOfClass:[NSNumber class] fallback:@(0)],
        @"message" : [json objectForKey:@"message" kindOfClass:[NSString class] fallback:@"Unknown"]
    };
}

+ (BATZAwareDate *)parseDate:(NSDictionary *)rawJson error:(NSError **)error {
    BATJsonDictionary *json =
        [[BATJsonDictionary alloc] initWithDictionary:rawJson errorDomain:@"com.batch.module.inapp.parser.error.date"];

    NSError *outErr;
    NSNumber *timestampNumber = [json objectForKey:@"ts" kindOfClass:[NSNumber class] allowNil:NO error:&outErr];
    if (timestampNumber == nil) {
        if (error) {
            *error = outErr;
        }
        return nil;
    }
    NSTimeInterval timestamp = [timestampNumber doubleValue];
    if (timestamp < 0) {
        if (error) {
            *error = [BALocalCampaignsParser genericParsingErrorForReason:@"Invalid timestamp"];
        }
        return nil;
    }

    NSNumber *userTZ = [json objectForKey:@"userTZ" kindOfClass:[NSNumber class] fallback:@(YES)];

    return [BATZAwareDate dateWithDate:[NSDate dateWithTimeIntervalSince1970:timestamp / 1000]
                      relativeToUserTZ:[userTZ boolValue]];
}

+ (NSError *)genericParsingErrorForReason:(NSString *)reason {
    return [NSError errorWithDomain:@"com.batch.module.localcampaigns.parser.error"
                               code:-20
                           userInfo:@{NSLocalizedDescriptionKey : reason}];
}

@end
