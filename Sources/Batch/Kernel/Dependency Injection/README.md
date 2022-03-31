#  Dependency injection

This is Batch's Depencency Injection framework

It allows you to fetch instances of object by class or protocol.

It doesn't manage a dependency graph yet

## Getting a dependency

BAInjection provides dependencies by class, or by protocol.

Note: you cannot get something that has been registered by protocol using its class, and vice versa.

## Providing a new implementation

Use BAInjectable to describe a new injectable class.

Ex:

```
BAInjectable *lcInjectable = [BAInjectable injectableWithInitializer: ^id () {
                                return [BALocalCampaignsManager new];
                              }];
                         
[BAInjection registerInjectable:lcInjectable
                    forProtocol:@protocol(BALocalCampaignsCenterProtocol)];


BAInjectable *lcInjectable = [BAInjectable injectableWithInitializer: ^id () {
                                return [BALocalCampaignsManager new];
                             }];
                         
[BAInjection registerInjectable:lcInjectable
                       forClass:[BALocalCampaignsCenter class]];
```

All injected instances are lazily loaded using the block provided to BAInjectable. Caution: they are called on every injection!

If you need to inject singletons, use a dispatch_once
The library cannot do this for you, as dispatch_once_t variables must be static.

```
BAInjectable *lcInjectable = [BAInjectable injectableWithInitializer: ^id () {
                                static id singleInstance = nil;
                                static dispatch_once_t once;
                                dispatch_once(&once, ^{
                                  singleInstance = [BALocalCampaignsManager new];
                                });
                                return singleInstance;
                            }];
                         
[BAInjection registerInjectable:lcInjectable
                   forProtocol:@protocol(BALocalCampaignsCenterProtocol)];

// A macro is also available

BAInjectable *lcInjectable = [BAInjectable injectableWithInitializer: ^id () {
                                bainjection_initializer_singleton([BALocalCampaignsManager new]);
                             }];
                         
[BAInjection registerInjectable:lcInjectable];
                    forProtocol:@protocol(BALocalCampaignsCenterProtocol)];
```


A second variant is one that allows the injection of instances directly: This is when you do not want lazy loading and manage singletons yourself:

```
BAInjectable *lcInjectable = [BAInjectable injectableForProtocol:@protocol(BALocalCampaignsCenterProtocol)
                                                        instance:[BALocalCampaignsManager shared]];
                         
[BAInjection registerInjectable:lcInjectable];
                    forProtocol:@protocol(BALocalCampaignsCenterProtocol)];

or 

// Your instance will be available in the "instance" variable
bainjection_instance_singleton([BALocalCampaignsManager new]);

BAInjectable *lcInjectable = [BAInjectable injectableWithInstance:instance];
[BAInjection registerInjectable:lcInjectable
                    forProtocol:@protocol(BALocalCampaignsCenterProtocol)];

```

>Note: Consider adding "BATCH_USE_INJECTION_OUTSIDE_TESTS" after your init signature to tell developers that classes should not be instanciated directly 

All injectables classes are declared in `BAInjectionRegistrar.m`. Its allow us to handle declaration order and prevent dependency issues. Registration is done only once during the first injection.

## Testing

A huge part of depencency injection is to be able to change what is injected in tests.

BAInjection allows to easily to do this by letting you add overlays to what would be returned by BAInjection. As opposed to the initializer, the block is always called.

Overlaying an injection returns an object that must be retained:
This is similar to OCMock

```

@interface LocalCampaignsMock: NSObject <BALocalCampaignsCenterProtocol> 

@end

@interface MyTest: XCTestcase

@property BAOverlayedInjectable *eventTrackerOverlay;

...

- (void)setUp {
    id eventTrackerMock = OCMClassMock([BAEventTracker class]);
    // This overlay will stay for all tests
    self.eventTrackerOverlay = [BAInjection overlayProtocol:@protocol(BAEventTrackerProtocol)
                                                    callback:^id(id originalObject) {
                                                        return eventTrackerMock;
    }];
}

- (void)myMockingTest {
    // This overlay will be gone once this method ends
    LocalCampaignsMock *lcMock = [LocalCampaignsMock new];
    // This syntax is a shortcut for the block one when you only want to return a value
    id lcOverlay = [BAInjection overlayProtocol:@protocol(BALocalCampaignsCenterProtocol) returnedInstance:lcMock];
}
```

Warning: Overlays are removed once the object gave back to you by BAInjection
nil-ing the value might not be enough to clear an overlay due to autorelease pools.
Use [BAInjection removeOverlay:] to remove it, or wrap your code in @autoreleasepool and nil the variable at the end
