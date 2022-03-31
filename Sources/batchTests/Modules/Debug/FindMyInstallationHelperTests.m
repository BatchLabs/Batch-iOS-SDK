//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "BADBGFindMyInstallationHelper.h"
#import "OCMock.h"

@interface BATrackerCenter ()

// Expose the private methods
- (BAConcurrentQueue *)queue;

@end

@interface FindMyInstallationHelperTests : XCTestCase

@end

@interface BADBGFindMyInstallationHelper (Tests)
- (void)notifyForeground;
@end

@implementation FindMyInstallationHelperTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Clearing FIND_MY_INSTALLATION events
    [[[BATrackerCenter instance] queue] clear];
}

- (void)testInstallationIdInClipboard {
    id pasteboardMock = OCMClassMock([UIPasteboard class]);
    BADBGFindMyInstallationHelper *helper = [[BADBGFindMyInstallationHelper alloc] initWithPasteboard:pasteboardMock];
    NSString *message = [NSString stringWithFormat:@"Batch Installation ID: %@", [BatchUser installationID]];
    [helper notifyForeground];
    [helper notifyForeground];
    [helper notifyForeground];
    XCTAssertTrue([((NSMutableArray *)[helper valueForKey:@"_timestamps"]) count] == 3);
    [helper notifyForeground];
    OCMVerify([pasteboardMock setString:message]);
    XCTAssertTrue([((NSMutableArray *)[helper valueForKey:@"_timestamps"]) count] == 0);
}

- (void)testInstallationIdNotInClipboard {
    id pasteboardMock = OCMClassMock([UIPasteboard class]);
    NSString *userID = [BatchUser installationID];
    OCMReject([pasteboardMock setString:userID]);
    BADBGFindMyInstallationHelper *helper = [[BADBGFindMyInstallationHelper alloc] initWithPasteboard:pasteboardMock];

    NSMutableArray *timestamps = (NSMutableArray *)[helper valueForKey:@"_timestamps"];

    NSNumber *now = @(floor([[NSDate date] timeIntervalSince1970] * 1000) - 13000);
    [timestamps addObject:now];

    [helper notifyForeground];
    [helper notifyForeground];
    [helper notifyForeground];
    [helper notifyForeground];
}

- (void)testEnablesFindMyInstallation {
    id pasteboardMock = OCMClassMock([UIPasteboard class]);
    BADBGFindMyInstallationHelper *helper = [[BADBGFindMyInstallationHelper alloc] initWithPasteboard:pasteboardMock];

    // Check default value is true
    XCTAssertTrue([BADBGFindMyInstallationHelper enablesFindMyInstallation]);

    [BADBGFindMyInstallationHelper setEnablesFindMyInstallation:false];
    [helper notifyForeground];
    XCTAssertTrue([((NSMutableArray *)[helper valueForKey:@"_timestamps"]) count] == 0);

    [BADBGFindMyInstallationHelper setEnablesFindMyInstallation:true];
    [helper notifyForeground];
    XCTAssertTrue([((NSMutableArray *)[helper valueForKey:@"_timestamps"]) count] == 1);
}

@end
