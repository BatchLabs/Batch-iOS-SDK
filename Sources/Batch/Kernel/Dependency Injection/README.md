# Dependency injection

Batch's own injection container. It resolves an instance from a class or a protocol, and it does not
manage a dependency graph.

What it retains follows from the registry being a plain map: an injectable lives as long as its
entry, and registering again for the same key replaces — and may release — the previous one. An
instance-backed injectable retains the object you handed it; a block-backed one retains the block,
which under ARC retains whatever it captures.

## Getting a dependency

```objc
BAMessagingCenter *center = [BAInjection injectClass:BAMessagingCenter.class];
id<BATEventTrackerProtocol> tracker = [BAInjection injectProtocol:@protocol(BATEventTrackerProtocol)];
```

Both are `NS_REFINED_FOR_SWIFT`, so Swift sees a single generic entry point:

```swift
let tracker: BATEventTracker? = BAInjection.inject(BATEventTracker.self)
```

Mind the two names: the Swift protocol is `BATEventTracker`, and `BATEventTrackerProtocol` is only
the Objective-C runtime name its `@objc(…)` annotation sets. The Objective-C sample above and this
one reach the same registration.

`inject(_:)` takes a class or a protocol. Structs are not supported.

**The class table and the protocol table are disjoint.** Something registered for a protocol cannot
be injected by its class, and the reverse. There is no fallback between the two.

**An unregistered key resolves to `nil`, silently** — no assert, no log, no exception. A class that
was never added to the registrar surfaces as a `nil` far away from the cause, usually as a method
call that quietly does nothing.

## Registering an injectable

Every registration lives in `BAInjectionRegistrar.registerInjectables`. `BAInjectionRegistry` runs it
once, under a `dispatch_once`, on the **first injection of any key** — not at SDK start.

There are two kinds of injectable, and the difference is when the instance is built.

`injectableWithInstance:` hands back the same object on every injection. Its argument is an ordinary
expression, so it is evaluated while the registrar runs — which means the first injection of any key
instantiates every eagerly registered object in the file.

```objc
[BAInjection registerInjectable:[BAInjectable injectableWithInstance:[BADomainManager sharedInstance]]
                    forProtocol:@protocol(BADomainManagerProtocol)];
```

`injectableWithInitializer:` runs its block **on every injection**. Without a `dispatch_once` inside
the block, every caller gets a fresh object:

```objc
[BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
               return [BALocalCampaignsFilePersistence new];
             }]
                    forProtocol:@protocol(BALocalCampaignsPersisting)];
```

A block-backed singleton therefore carries its own `dispatch_once`, because `dispatch_once_t` has to
be static and the container cannot supply one:

```objc
[BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
               static id singleInstance = nil;
               static dispatch_once_t once;
               dispatch_once(&once, ^{
                 singleInstance = [BAEventDispatcherCenter new];
               });
               return singleInstance;
             }]
                       forClass:BAEventDispatcherCenter.class];
```

`BAInjection.h` also defines a `bainjection_instance_singleton` macro, which expands to that
`static` plus `dispatch_once` and returns the instance. Searching the sources for it
(`grep -rn bainjection_instance_singleton sdk --include='*.m' --include='*.h' --include='*.swift'`)
turns up only the definition, so the inline form above is the pattern to follow.

Mark a method whose result should come from injection rather than from a direct call with the
`BATCH_USE_INJECTION_OUTSIDE_TESTS` annotation after its signature. It is not limited to class
methods: it sits on `+instance` factories, and on an instance initializer such as
`-initWithWrappedDelegate:` on `BAMessagingAnalyticsDeduplicatingDelegate`. It expands to nothing;
it exists to tell a reader.

## Overlays, for tests

An overlay replaces what injection returns for one key. Its callback receives the instance the
registry would have produced, so an overlay can wrap the real object rather than replace it, and it
is consulted on **every** injection — including for a key registered with `injectableWithInstance:`,
where no initializer block runs at all.

```objc
BAOverlayedInjectable *overlay =
    [BAInjection overlayProtocol:@protocol(BATEventTrackerProtocol)
                returnedInstance:OCMClassMock([BATrackerCenter class])];
```

`overlayClass:` and `overlayProtocol:` each come in a `callback:` and a `returnedInstance:` form.

Three properties decide how tests have to be written:

- **The registry holds overlays weakly** (`strongToWeakObjectsMapTable`). The returned
  `BAOverlayedInjectable` is the only strong reference. Drop it — assign to `_`, let it fall out of
  an autorelease pool — and later injections silently hit the real implementation again.
- **One overlay per key.** Registering a second overlay for the same class or protocol replaces the
  first; they do not stack.
- **Teardown is `+unregisterOverlay:`**, which removes every key pointing at that overlay. There is
  no `removeOverlay:` on `BAInjection`. `removeOverlay(_:)` in `sdk/batchTests/XCTest+Injection.swift`
  is a different thing entirely — a `withExtendedLifetime` call that *keeps the overlay alive*, and
  removes nothing.

Because overlays live in process-wide state, one per key, two suites overlaying the same key must
not run concurrently. How a suite states that depends on its test framework — see `sdk/AGENTS.md`
for the test-side rules.
