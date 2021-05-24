//
//  batchOptOutTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Batch/Batch.h>
#import "BAOptOut.h"
#import "BAInstallationID.h"
#import "BAParameter.h"
#import "BAOptOutEventTracker.h"
#import "BAJson.h"
#import "BACoreCenter.h"
#import "BALocalCampaignsManager.h"
#import "BALocalCampaignsCenter.h"
#import "BALocalCampaignsFilePersistence.h"

#import "OCMock.h"

@interface BALocalCampaignsFilePersistence ()
- (NSURL*)filePath;
@end

@interface BALocalCampaignsCenter ()
- (id<BALocalCampaignsPersisting>)campaignPersister;
@end

@interface dummyOptOutEventTracker : BAOptOutEventTracker

@property (strong) BAEvent *lastTrackedEvent;

@property (strong) BAPromise *lastTrackPromise;

@end

@interface batchOptOutTests : XCTestCase

@property (nonatomic, assign) id coreCenterStatusMock;

@end

@implementation batchOptOutTests

+ (void)setUp {
    [self clearOptOutStatus];
}

- (void)setUp {
    id coreCenterStatusMock = OCMPartialMock([[BACoreCenter instance] status]);
    OCMStub([coreCenterStatusMock isRunning]).andReturn(true);
}

- (void)tearDown {
    [_coreCenterStatusMock stopMocking];
    _coreCenterStatusMock = nil;

    [batchOptOutTests clearOptOutStatus];
}

- (void)testPublicAPI {
    id optOutMock = OCMClassMock([BAOptOut class]);
    OCMStub([optOutMock instance]).andReturn(optOutMock);
    
    [Batch optOut];
    OCMVerify([optOutMock setOptedOut:true wipeData:false completionHandler:[OCMArg any]]);
    
    [Batch optIn];
    OCMVerify([optOutMock setOptedOut:false wipeData:false completionHandler:[OCMArg any]]);
    
    [Batch optOutAndWipeData];
    OCMVerify([optOutMock setOptedOut:true wipeData:true completionHandler:[OCMArg any]]);
    
    [Batch optOutWithCompletionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        return BatchOptOutNetworkErrorPolicyCancel;
    }];
    OCMVerify([optOutMock setOptedOut:true wipeData:false completionHandler:[OCMArg any]]);
    
    [Batch optOutAndWipeDataWithCompletionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        return BatchOptOutNetworkErrorPolicyCancel;
    }];
    OCMVerify([optOutMock setOptedOut:true wipeData:true completionHandler:[OCMArg any]]);
    
}

- (void)testOptOutWithoutWiping
{
    NSString *oldInstallID = [BAInstallationID installationID];
    
    id parameterMock = OCMClassMock([BAParameter class]);
    id installIDMock = OCMClassMock([BAInstallationID class]);

    id optOutMock = OCMClassMock([BAOptOut class]);
    OCMStub([optOutMock initEventTrackerIfNeeded]);
    
    OCMReject(ClassMethod([parameterMock removeAllObjects]));
    OCMReject(ClassMethod([installIDMock delete]));
    
    [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:nil];
    
    [installIDMock stopMocking];
    
    XCTAssertNil([BAInstallationID installationID]);
    XCTAssertTrue([[BAOptOut new] isOptedOut]);
    
    // Make BAInstallationID returns the old installation id
    [batchOptOutTests clearOptOutStatus];
    NSString *newInstallID = [BAInstallationID installationID];
    XCTAssertNotNil(newInstallID);
    XCTAssertEqualObjects(oldInstallID, newInstallID);
    
    [parameterMock stopMocking];
}

- (void)testWipeData
{
    NSString *oldInstallID = [BAInstallationID installationID];
    
    id parameterMock = OCMClassMock([BAParameter class]);
    id installIDMock = OCMClassMock([BAInstallationID class]);
    
    id optOutMock = OCMClassMock([BAOptOut class]);
    OCMStub([optOutMock initEventTrackerIfNeeded]);
    
    OCMExpect(ClassMethod([parameterMock removeAllObjects])).andForwardToRealObject();
    OCMExpect(ClassMethod([installIDMock delete])).andForwardToRealObject();

    BALocalCampaignsCenter *campaignsCenter = [BALocalCampaignsCenter instance];

    // Load some campaigns
    [[campaignsCenter campaignPersister] persistCampaigns:@{}];
    // Wait for data to be written on disk
    sleep(1);

    // Make sure campaigns file is on disk
    NSString *filePath = ((BALocalCampaignsFilePersistence*)[campaignsCenter campaignPersister]).filePath.path;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filePath]);

    [[BAOptOut instance] setOptedOut:true wipeData:true completionHandler:nil];
    
    OCMVerifyAll(parameterMock);
    OCMVerifyAll(installIDMock);
    XCTAssertTrue([[BAOptOut new] isOptedOut]);
    
    [installIDMock stopMocking];
    
    XCTAssertNil([BAInstallationID installationID]);
    
    // Make BAInstallationID return a new installation id by removing the opt out
    [batchOptOutTests clearOptOutStatus];
    NSString *newInstallID = [BAInstallationID installationID];
    XCTAssertNotNil(newInstallID);
    XCTAssertNotEqualObjects(oldInstallID, newInstallID);
    
    [parameterMock stopMocking];

    // Make sure campaigns file was deleted
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
}

- (void)testEvents
{
    // Neuter the opt out before applying
    id optOutMock = OCMClassMock([BAOptOut class]);
    OCMStub([optOutMock applyOptOut:[OCMArg any] wipeData:[OCMArg any]]);
    
    NSString *installID = [BAInstallationID installationID];
    XCTAssertNotNil(installID);
    
    dummyOptOutEventTracker *tracker = [dummyOptOutEventTracker new];
    BAOptOut *optOut = [BAOptOut instance];
    [optOut setEventTracker:tracker];
    
    [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:nil];
    [batchOptOutTests clearOptOutStatus];
    
    BAEvent *event = [tracker lastTrackedEvent];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(@"_OPTOUT", event.name);
    XCTAssertEqualObjects(installID, [self dictionaryFromEventParameters:event][@"di"]);
    
    [[BAOptOut instance] setOptedOut:true wipeData:true completionHandler:nil];
    [batchOptOutTests clearOptOutStatus];

    event = [tracker lastTrackedEvent];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(@"_OPTOUT_WIPE_DATA", event.name);
    XCTAssertEqualObjects(installID, [self dictionaryFromEventParameters:event][@"di"]);
}

- (void)testOptOutCallbacks
{
    dummyOptOutEventTracker *tracker = [dummyOptOutEventTracker new];
    BAOptOut *optOut = [BAOptOut instance];
    [optOut setEventTracker:tracker];
    
    // Setup all exepectations at once
    // We test stuff that has already been tested but it's way easier than removing a stub
    id stubbedOptOut = OCMPartialMock(optOut);
    OCMExpect([stubbedOptOut applyOptOut:true wipeData:false]);
    OCMExpect([stubbedOptOut applyOptOut:true wipeData:true]);
    OCMExpect([stubbedOptOut applyOptOut:true wipeData:false]);
    OCMExpect([stubbedOptOut applyOptOut:true wipeData:true]);
    OCMReject([stubbedOptOut applyOptOut:true wipeData:false]);
    OCMReject([stubbedOptOut applyOptOut:true wipeData:true]);
    
    XCTestExpectation *latestExpectation;
    
    // Success callbacks
    
    latestExpectation = [self expectationWithDescription:@"Opt-out, no wipe data, success"];
    [stubbedOptOut setOptedOut:true wipeData:false completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertTrue(success);
        [latestExpectation fulfill];
        return BatchOptOutNetworkErrorPolicyIgnore;
    }];
    [tracker.lastTrackPromise resolve:nil];
    [self waitForExpectations:@[latestExpectation] timeout:1];
    
    latestExpectation = [self expectationWithDescription:@"Opt-out, wipe data, success"];
    [stubbedOptOut setOptedOut:true wipeData:true completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertTrue(success);
        [latestExpectation fulfill];
        return BatchOptOutNetworkErrorPolicyIgnore;
    }];
    [tracker.lastTrackPromise resolve:nil];
    [self waitForExpectations:@[latestExpectation] timeout:1];
    
    // Failure callbacks
    
    latestExpectation = [self expectationWithDescription:@"Opt-out, no wipe data, failure, cancel"];
    [stubbedOptOut setOptedOut:true wipeData:false completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertFalse(success);
        [latestExpectation fulfill];
        return BatchOptOutNetworkErrorPolicyCancel;
    }];
    [tracker.lastTrackPromise reject:nil];
    [self waitForExpectations:@[latestExpectation] timeout:1];
    
    latestExpectation = [self expectationWithDescription:@"Opt-out, wipe data, failure, cancel"];
    [stubbedOptOut setOptedOut:true wipeData:true completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertFalse(success);
        [latestExpectation fulfill];
        return BatchOptOutNetworkErrorPolicyCancel;
    }];
    [tracker.lastTrackPromise reject:nil];
    [self waitForExpectations:@[latestExpectation] timeout:1];
    
    // Do the force callbacks at the end, as we will start rejecting the calls
    
    latestExpectation = [self expectationWithDescription:@"Opt-out, no wipe data, failure, force"];
    [stubbedOptOut setOptedOut:true wipeData:false completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertFalse(success);
        [latestExpectation fulfill];
        return BatchOptOutNetworkErrorPolicyIgnore;
    }];
    [tracker.lastTrackPromise reject:nil];
    [self waitForExpectations:@[latestExpectation] timeout:1];
    
    latestExpectation = [self expectationWithDescription:@"Opt-out, wipe data, failure, force"];
    [stubbedOptOut setOptedOut:true wipeData:true completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertFalse(success);
        [latestExpectation fulfill];
        return BatchOptOutNetworkErrorPolicyIgnore;
    }];
    [tracker.lastTrackPromise reject:nil];
    [self waitForExpectations:@[latestExpectation] timeout:1];
    
    OCMVerifyAll(stubbedOptOut);
}

- (void)testAlreadyOptedOutCallback
{
    id optOutMock = OCMClassMock([BAOptOut class]);
    OCMStub([optOutMock initEventTrackerIfNeeded]);
    
    [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Batch opt-out callback"];
    [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
        return BatchOptOutNetworkErrorPolicyCancel;
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

+ (void)clearOptOutStatus
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:OptOutUserDefaultsSuite];
    NSDictionary *dict = defaults.dictionaryRepresentation;
    for (NSString *key in dict.allKeys) {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
    [[BAOptOut instance] refresh];
}

- (NSDictionary*)dictionaryFromEventParameters:(BAEvent*)event
{
    return [BAJson deserializeAsDictionary:event.parameters error:nil];
}

@end


@implementation dummyOptOutEventTracker

- (BAPromise*)track:(BAEvent *)event
{
    self.lastTrackedEvent = event;
    BAPromise *promise = [BAPromise new];
    self.lastTrackPromise = promise;
    return promise;
}

@end

/*
 + (void)optOut
 {
 [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:nil];
 }
 
 + (void)optOutAndWipeData
 {
 [[BAOptOut instance] setOptedOut:true wipeData:true completionHandler:nil];
 }
 
 + (void)optOutWithCompletionHandler:(BatchOptOutNetworkErrorPolicy(^ _Nonnull)(BOOL success))handler
 {
 [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:handler];
 }
 
 + (void)optOutAndWipeDataWithCompletionHandler:(BatchOptOutNetworkErrorPolicy(^ _Nonnull)(BOOL success))handler
 {
 [[BAOptOut instance] setOptedOut:true wipeData:true completionHandler:handler];
 }
 
 + (void)optIn
 {
 [[BAOptOut instance] setOptedOut:false wipeData:false completionHandler:nil];*/
