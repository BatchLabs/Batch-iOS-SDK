# Batch iOS SDK — Architecture

What you need in your head before changing anything under `sdk/Batch/`. Every claim here names the file and symbol that proves it; when in doubt, the code wins — and fix this file in the same commit. Paths are relative to `sdk/Batch/` unless they start with `sdk/`.

## 1. Startup sequence

```
BatchSDK.startWithAPIKey:            BatchCore.m          public facade, one-line delegate
  └─ BACenterMulticastDelegate       Modules/Core         orchestrator
       ├─ BALogger.setup
       ├─ reject if key is nil or BAOptOut.instance.isOptedOut
       ├─ every plugin: batchWillStart
       ├─ BACoreCenter.startWithAPIKey:                   flips BAStatus, starts the webservice
       └─ every plugin: batchDidStart
```

- `kPluginsList` in `BACenterMulticastDelegate.m` is the module registry the start path iterates — a static array built in `+initialize`. A Center that is not in that array gets no `batchWillStart` and no `batchDidStart`: it still compiles, and nothing warns you. Read the array itself for the current membership and start order.
- `batchWillStart` and `batchDidStart` are `@optional` and invoked through `respondsToSelector:`. A typo in either name is a silent no-op, not a compile error. Membership is not visible through the protocol either: Swift Centers sit in `kPluginsList` without conforming to `BACenterProtocol` — `BAProfileCenter.swift` carries a comment saying it cannot — so neither grepping `.m` files nor grepping the protocol tells you who implements a hook.
- The ordering is load-bearing: every `batchWillStart` runs **before** `BACoreCenter.startWithAPIKey:` flips `BAStatus` to running. `BATrackerCenter.batchWillStart` depends on exactly that — it guards on `![[BACoreCenter instance].status isRunning]`, so calling `startWithAPIKey:` again while the SDK is still running does not subscribe it to `kBATOptOutChangedNotification` twice. That guard buys nothing across a background cycle: `DidEnterBackground` runs `BAStatus.stop`, so the next start sees `isRunning == NO` and registers the observer again.
- `BACoreCenter.excecuteStartWithAPIKey:` binds `stop` to `UIApplicationWillTerminate`/`DidEnterBackground` and `restart:` to `WillEnterForeground` — inside the `if (e == nil)` branch only, and `BAStatus.initialization` returns an error once `_init` is set, so those three observers are bound on the first successful initialisation and never re-bound. "Started" then flips on every backgrounding. The `restart:` call at the end of the method sits outside that branch, so it runs on every start that got past `setDevelopperKey:` — an empty or rejected key returns before it.
- Two observers do not wait for a start at all: `BAPushCenter` and `BAMessagingCenter` register theirs on `[NSNotificationCenter defaultCenter]` from `+load`, for `UIApplicationDidFinishLaunchingNotification` and `BatchPushOpenedNotification`. When `BatchPushOpenedNotification` is posted depends on the path, and the two do not agree: the runtime one is gated on the SDK having been initialised at least once, while `BAPushCenter.batchWillStart` replays the payload it stored at launch (`startPushUserInfo`) before `BACoreCenter` ever calls `BAStatus.initialization`. So a cold-start open reaches `BAMessagingCenter` with `isInitialized` still false.
- Spelling traps when grepping: the config key accessor is `developperKey`, with two p's — the correctly spelled form appears in no implementation file — and the core method is `excecuteStartWithAPIKey:`.

## 2. State and configuration

- `BAStatus` (`Modules/Core`) holds the lifecycle flags; reach it via `BACoreCenter.instance.status`. `initialization` is what creates and hands out `BASessionManager` and `BANotificationAuthorization`, so neither exists until it has run. Its `trackingAuthorization` property is declared `nonnull`, but `BATrackingAuthorization` is only forward-declared — no implementation exists and `initialization` never assigns it, so it always vends `nil`.
- `isInitialized` is sticky, but it means **a successful `BAStatus.initialization`** — not "someone called `startWithAPIKey:`", which is what its own header comment claims. `BAStatus` sets the flag nowhere else, and the call never reaches `initialization` when the key is nil, when `BAOptOut.instance.isOptedOut` (both rejected by `BACenterMulticastDelegate.startWithAPIKey:`), or when `BAConfiguration.setDevelopperKey:` returns an error. `isRunning` follows foreground/background once the observers of §1 are bound.
- `BAStatus.start`/`stop` **return an `NSError` when the transition is a no-op, and mutate state anyway**. Callers use that error as "was already started". Reading it as a failure inverts the logic. `initialization` is the one that behaves conventionally: it returns its error *instead of* mutating.
- `BAConfiguration` (`Modules/Core`) posts `kBATConfigurationChangedNotification` from some setters and not others — `setDisabledMigrations:` and the synthesised `deeplinkDelegate` setter mutate silently. Read the setter body before assuming observers will fire.

## 3. Dependency injection

`Kernel/Dependency Injection/` has a README of its own; read it before touching injection.

- Single registration site: `Private/BAInjectionRegistrar.m`, run once via `dispatch_once` inside `BAInjectionRegistry.registerInjectablesIfNeeded` on the first injection.
- Two lifetimes that look alike: `injectableWithInstance:` captures an object built **at registration time** (so the first injection of any key instantiates every eagerly-registered object); `injectableWithInitializer:` re-runs its block **on every injection** — `BABlockInitializerInjectable.resolveInstance` calls it unconditionally — unless the block itself does a `dispatch_once`.
- Class-keyed and protocol-keyed tables are disjoint (`_classInjectables`, `_protocolInjectables`): something registered for a protocol cannot be injected by class, and vice versa.
- An unregistered key resolves to **`nil`, silently** — no assert, no log. A new injectable that is not in the registrar surfaces as a no-op far from the cause.
- Swift sees a single generic `BAInjection.inject(_:)` (`BAInjection.swift`); the Objective-C methods are `NS_REFINED_FOR_SWIFT`.
- Tests replace implementations with overlays; `_overlaysTable` is a `strongToWeakObjectsMapTable` holding one overlay per key. See `sdk/AGENTS.md` for the lifetime rules.

## 4. Module anatomy

Role suffixes are a naming habit, not a contract:

| Suffix | Usually means |
|---|---|
| `*Center` | process-wide singleton facade, usually an entry in `kPluginsList` |
| `*Manager` | stateful logic owned by a Center |
| `*Datasource` | two unrelated things: a SQLite store behind a `*DatasourceProtocol` (`*SQLiteDatasource`) or a query-webservice datasource (`*ServiceDatasource`, see §7) |
| `*Service` | a webservice endpoint: either a `BAQueryWebserviceClientDatasource` under `Webservices/Query Services Implementations/` or a `BAWebserviceJsonClient` subclass under `Webservices/JSON Services implementations/` (see §7) |
| `*Helper` | utility |
| `*Parser` | payload → model |

Counterexamples are load-bearing. `BADomainService` (`Modules/Domain/`) is an `@objc enum` that builds host strings — it has nothing to do with the webservice datasource protocol. `*Helper` promises least of all: `BAPushSystemHelper` is registered as an instance in `BAInjectionRegistrar` and injected through `BAPushSystemHelperProtocol`; `BATrackerSignpostHelper` owns an `os_log_t` created in `init`; `BAEventSQLiteHelper` and `BAInboxSQLiteHelper` implement instance binding methods (`bindEvent:withStatement:`, `bindNotification:…`); `BADBGFindMyInstallationHelper` takes a `UIPasteboard` in its initialiser and has class-level mutable state. **Inspect the declaration and the construction or injection site: the suffix determines neither lifetime nor API.**

- **`Modules/Local Campaigns/`** is the reference layout: `BALocalCampaignsCenter` (facade + signal bus) over `BALocalCampaignsManager` (eligibility), with the rest split into sub-directories by responsibility.
- **`Modules/Messaging/`** declares no `*Manager` and no `*Datasource` class — the `CEP/InApp/Manager/` directory is a folder name, and holds `InAppAnalyticWrapper`. The module is split by message generation instead (see §8).
- `BAPushCenter` decides *whether* to swizzle (`shouldSwizzle`, `swizzled`); the swizzling itself is `BADelegatedApplicationDelegate.findAndSwizzleAppDelegate` under `Kernel/Helpers/`.
- Singleton accessor naming is inconsistent — `+instance`, `+sharedInstance` and Swift `static let sharedInstance` all occur. Check the class before guessing.

## 5. Two notification buses

**Internal events go through `BANotificationCenter` (a private `NSNotificationCenter` subclass); public and system events go through `[NSNotificationCenter defaultCenter]`.** Posting on the wrong one compiles and silently never fires.

Internal (`[BANotificationCenter defaultCenter]`):

| Name | Declared in | Posted by | Observed by |
|---|---|---|---|
| `BATNewSessionStartedNotification` | `Modules/Core/BASessionManager.h` | `BASessionManager` | `BALocalCampaignsCenter` — the real per-session kick-off, except on visionOS: `setup` returns under `#if TARGET_OS_VISION` before registering, and `emitSignal:` returns under the same guard. `refreshCampaignsFromServer` itself is unguarded, so the `batch.refresh_lc` action still reaches the server there — what visionOS loses is the automatic per-session refresh and every signal that would display a campaign |
| `kBATConfigurationChangedNotification` | `Modules/Core/BAConfiguration.h` | `BAConfiguration` | — |
| `kBATOptOutChangedNotification` | `Modules/Opt Out/BAOptOut.h` | `BAOptOut`, with `kBATOptOutValueKey`/`kBATOptOutWipeDataKey` | `BATrackerCenter`, `BAUserCenter` |
| `kBATMessagingMessageDidAppear` | `Modules/Messaging/BAMessagingCenter.h` | `BAMessagingCenter` | `BAMSGBaseBannerViewController` |
| `kBATMessagingMessageDidDisappear` | `Modules/Messaging/BAMessagingCenter.h` | `BAMessagingCenter` | **nobody** — posted and never observed |
| `kBAReachabilityChangedNotification` | `Kernel/Reachability/BAReachability.h` | `BAReachability` | `BAReachabilityHelper` |
| `kNotificationBatchStarts` / `Stops` | `BANotificationCenter.h` | `BAStatus` | **nobody** — dead, despite the comment in `BALocalCampaignsCenter.batchWillStart` claiming otherwise |

Public (`[NSNotificationCenter defaultCenter]`, declared in public headers): `BatchPushOpenedNotification` (+ `BatchPushOpenedNotificationPayloadKey`), `BatchPushReceivedNotification` (deprecated), `BatchPushUserDidAnswerAuthorizationRequestNotification` in `BatchPush.h`; `BatchEventTrackerFinishedNotification` in `BatchUser.h`. Mobile landings work by `BAMessagingCenter` observing `BatchPushOpenedNotification`.

## 6. Persistence

Every **file-backed** row in the table below resolves its path through `[BADirectories pathForBatchAppSupportDirectory]`: `NSApplicationSupportDirectory` plus `BABundleIdentifier` (`@"com.batch.ios"`), created on demand by that method. The `NSUserDefaults`-backed rows do not: `BAUserDefaults` and `BAOptOut` each open a suite by name (`initWithSuiteName:`), so those values live wherever iOS keeps preference plists and no path of Batch's choosing applies.

| Store | File | Owner |
|---|---|---|
| Events | `ba_tr.db` | `BATrackerCenter` → `BAEventSQLiteDatasource` |
| Install/user data | `ba_user_profile.db` | `BAUserSQLiteDatasource` |
| Inbox | `ba_in.db` | `BAInboxSQLiteDatasource` (injected) |
| Local campaign views | `ba_local_campaigns_tracker.db` | `BALocalCampaignsSQLTracker` |
| Campaign payloads | `local_campaigns.json` | `BALocalCampaignsFilePersistence` |
| Install ID backup | `com.batch.ios.plist` (`+[BAInstallationID filePersistencePath]`) | `BAInstallationID` |
| Everything keyed | `NSUserDefaults` suite `com.batch.ios`, encrypted only for non-empty strings | `Kernel/Parameters/BAParameter` → `BAUserDefaults` |
| Opt-out flag | `NSUserDefaults` suite `com.batch.sdk.optout`, never encrypted | `BAOptOut` |

- Schema migrations are per-datasource and hand-rolled, versioned by a `BAParameter` key, with **"delete the database file" as the fallback for any unrecognised version** — the trailing `else if (![oldDbVesion isEqualToNumber:…])` branch. `BAEventSQLiteDatasource`, `BAInboxSQLiteDatasource` and `BALocalCampaignsSQLTracker` all read that version and, when it is unrecognised, delete the file before they open their connection, so bumping one of those schemas without adding its branch wipes user data. `BAUserSQLiteDatasource` has no such branch: its migration block is commented out and it opens straight through, so a schema change there has no upgrade path at all until you write one. It writes `USER_DB_VERSION` only once `sqlite3_open_v2`, both `create table if not exists` statements and the `COMMIT` have succeeded — each of those failing returns `nil` from the initialiser instead. That misspelt local, `oldDbVesion` (the `r` of "Version" is missing), is what hides the sites from a grep.
- `BAParameter` write semantics are a live trap. The class API is `+setValue:forKey:saved:`, the instance method it forwards to is `-setValue:forKey:save:` (no `d`); grepping for one misses the other. `save:NO` writes the **in-process cache only**, `save:YES` writes `NSUserDefaults` only — and `objectForKey:fallback:` reads cache → defaults → builtin → fallback. So a cached value set with `save:NO` shadows every later persisted write for the lifetime of the process.
- "Encrypted `NSUserDefaults`" is conditional: `BAUserDefaults` runs its cryptor only when `[BANullHelper isStringEmpty:value]` is `NO`, which requires an `NSString` of non-zero length. Everything else — numbers, dates, data, empty strings — goes into the suite unchanged and comes back the same way, so a value like the tracker's `DB_VERSION` (`@3`, an `NSNumber`) sits there in the clear. `BAParameter` always hands it a `BAAESB64Cryptor`, built in `-[BAParameter initWithSuiteName:]`; the parameter is `_Nullable`, and with no cryptor nothing is encrypted at all.
- The install ID's primary store is `BAParameter` under `kParametersLocalInstallIdentifierKey`; the file is a backup. `+[BAInstallationID installationID]` reads the parameter first and only falls back to the file, and a value recovered from the file is written back to the parameter. The file is written once, when a new ID is generated, and holds a single `BAAESB64Cryptor`-encrypted string — the `.plist` extension is the filename, not the format, since it is produced by `writeToFile:atomically:encoding:error:`. `+[BAInstallationID delete]` removes the parameter unconditionally but treats the file as best effort: a failed `removeItemAtPath:` is only logged, so a surviving backup can resurrect the ID on the next read.
- "Migration" is overloaded, and the three meanings share no code: `BatchMigration` (the public `NS_OPTIONS` in `BatchCore.h`, install data → profile data), SQLite schema migrations (above), and `BACoreCenter.portDataFromVersion:`, which only logs.

## 7. Networking

`Webservices/README.md` walks the request pipeline; read it first.

- What a request looks like is decided by the layer you subclass: `BAWebserviceClient` (an `NSOperation`) → `BAWebserviceJsonClient` (serialises `requestBodyArray` or `requestBodyDictionary`) → `BAQueryWebserviceClient` (the query envelope). `BAGETWebserviceClient` is the GET branch off the JSON client.
- The query envelope packs several queries per HTTP request and matches them to their responses by `BAWSQuery.identifier`, a `BARandom.generateUUID`. Clients that subclass `BAWebserviceJsonClient` directly bypass it and POST their own body — `BAMetricWebserviceClient` returns a bare array from `requestBodyArray`, `BAInboxSyncWebserviceClient` and `BALocalCampaignsJITService` a dictionary. **Check the superclass before assuming the envelope.**
- Encryption is not a property of the service: `BAWebserviceCryptorFactory` decides. Outbound it returns a real cryptor when `BAConnection.contentType` is `BAConnectionContentTypeJSON`; inbound it also requires a non-empty response body, so an empty JSON reply is handed to the `BAWebserviceStubCryptor` — as is every non-JSON exchange. Override `BAWebserviceClient.cryptorFactory` to change it.
- URL shape, built by `BAWebserviceURLBuilder.webserviceURLForHost:shortname:apiKey:`: `<host>/i/<sdkVersion>/<shortname>/<apiKey>`. The host comes from `BADomainManager.url(for:overrideWithOriginal:)`; `BADomainService` maps `.web` to `https://ws.<domain>` and `.metric` to `https://wsmetrics.<domain>/api-sdk`.
- Shortnames are the `kParameters*WebserviceShortname` block in `Defined.h`. The JIT ones are assembled by literal concatenation — `kParametersLocalCEPCampaignsJITWebserviceShortname` expands `kParametersLocalCampaignsWebserviceShortname @"_" kParametersLocalCampaignsJITWebserviceShortname @"_" kParametersLocalCEPJITWebserviceShortname` — so the string `inapp_jit_cep` never appears in `Defined.h` and renaming any one part silently renames an endpoint. `BALocalCampaignsJITService` picks the MEP or the CEP shortname off `BALocalCampaignsVersion` in its initialiser.
- Adding a service: settle which of the two shapes you are writing first. If the endpoint speaks the query envelope and should ride along with the other queries, you are writing a **datasource** and `BAQueryWebserviceClient` is the client. If it has its own request body and its own response, you subclass the JSON client yourself — that is `BALocalCampaignsJITService`: it extends `BAWebserviceJsonClient`, builds its own URL, overrides `requestBodyDictionary`, conforms to `BAConnectionDelegate` to unpack its own response, and implements neither the datasource protocol nor any `BAWSQuery*`/`BAWSResponse*` model. `Webservices/JSON Services implementations/` holds that one client and nothing else: the other JSON clients sit with their module instead (`BAMetricWebserviceClient` under `Modules/Metrics/`, `BAInboxSyncWebserviceClient` and `BAInboxFetchWebserviceClient` under `Modules/Inbox/`), so grep the superclass, not the directory, to find them.
- Adding a **query** service: implement `BAQueryWebserviceClientDatasource` (`requestURL`, `requestIdentifier`, `requestShortIdentifier`, `queriesToSend`, `responseForQuery:content:`), add the `BAWSQuery*`/`BAWSResponse*` models under `Query Services Implementations/`, then `[[BAQueryWebserviceClient alloc] initWithDatasource:… delegate:…]` and hand it to `BAWebserviceClientExecutor.sharedInstance.addClient:`. Don't trust the file name to tell you the class name there: a header called `BAStartService.h` declares `BAStartServiceDatasource`, and the `BAQueryWebserviceClientDelegate` half is sometimes a second class in the same header (`BALocalCampaignsServiceDelegate`) and sometimes the datasource itself (`BAEventTrackerService` conforms to both). New headers also need the private-header bookkeeping in `sdk/AGENTS.md`.
- **`BAConnection` performs no automatic retry** — the `numberOfRetry` in its header comment names no symbol in any implementation, and `BAWebserviceClientExecutor` only caps concurrency (`maxConcurrentOperationCount`). Backoff is each service's own business, and each does it differently. `BATrackerScheduler` owns an exponential `_retryTimer` between `_initialRetryDelay` and `_maxRetryDelay`, re-fired early by `reachabilityChanged`. The metric and JIT paths instead honour a server deadline, and the read happens at a different layer in each: `BAConnection` puts the parsed `Retry-After` header into the error `userInfo` under the key `retryAfter`; `BAMetricManager` reads that `userInfo` itself in its failure block and sets `_nextAvailableMetricServiceTimestamp`, whereas on the JIT path `BALocalCampaignsJITService.retryAfter:` does the extraction and hands an `NSNumber` to its error block, which `BALocalCampaignsManager` forwards to `setNextAvailableJITTimestampWithCustomDelay:`. That block takes `^(NSError *error, NSNumber *retryAfter)`, so the manager holds the error and never reads it — and its guard, `(delay == nil ? 0 : delay) <= 0`, compares the `NSNumber` *pointer*, so it substitutes its default for a nil delay but lets a negative one through into the deadline unchanged.
- `NSError` domains are not centralised, and `LOCAL_ERROR_DOMAIN` is the trap: several `.m` files each `#define` it to a **different** value, so grepping the name across the SDK looks like one shared constant and is not. Check which file you are in before keying anything on a domain. The shared domains are the `*ERROR_DOMAIN` `#define`s in `Supporting Files/Defined.h`; some code skips both and builds a domain from an inline string literal instead (`BAMSGImageDownloader` and `BALocalCampaignsParser`, among others — grep `errorWithDomain:@"` for the current set). So a domain you match on may not be a symbol anywhere.

## 8. Two generations, side by side

- **Messaging**: CEP (`Modules/Messaging/CEP/`, Swift, `InApp*` types) is canonical for new work; MEP (the `BAMSG*` view controllers, `Widgets/` and `CSS/` under `Modules/Messaging/`) is maintenance-only. The fork is the `[message isCEPMessage]` branch in `BAMessagingCenter`. `BAMSGPayloadParser` parses both envelopes (`messageForMEPRawMessage:bailIfNotAlert:`, `messageForCEPRawMessage:bailIfNotAlert:`); the CEP body itself decodes into the Swift `Codable` `InApp*` types. A fix applied to one generation does not reach the other.
- **User data**: `BatchProfile`/`BATProfileEditor` (profile-scoped) supersedes `BatchUser`/`BAInstallDataEditor` (install-scoped). The mirrored surface is exactly `BATInstallDataEditorCompatibilityProtocol`: `BATProfileEditor` forwards to `compatibilityDelegate` — set only if `enableInstallCompatibility()` ran — and wraps each of those calls in `try?`. Where a failure can actually be swallowed is narrower than that suggests. The protocol declares every method but `consume()` as `throws`; `BATProfileInstallDataCompatibility`, its only implementation, throws from none of them. Language, region, array add/remove, the string-array setter, the attribute delete and `consume` all call `void`-returning `BAInstallDataEditor` methods (`setLanguage:`, `setRegion:`, `addTag:inCollection:`, `removeTag:fromCollection:`, `clearTagCollection:`, `removeAttributeForKey:`, `save`), so there is nothing there to swallow. Only the typed custom-attribute setters reach a throwing API — the `set<Type>Attribute:forKey:error:` family, all `NS_SWIFT_NAME`d to `setAttribute(_:forKey:)` — and each wraps it in its own `try?`: that is the one place the install store can reject a value the profile store accepted, silently. Setters with no counterpart in that protocol (email, phone number, the marketing subscription states, topic preferences) are profile-only by design. `profileEditorCompatibilityTest` pins the mirrors that exist today with an OCMock expectation per install-editor call; it does not enumerate the editor's API, so adding a mirrorable setter without its mirror desynchronises the two stores forever, with no error and nothing failing.
- See `sdk/DOMAIN.md` for what MEP and CEP mean on the backend, and for the payload discriminators.

## 9. Threading

There is no global threading model: contracts are per-class, mostly undocumented, and held up by convention. Before calling an internal method from a new thread, look for an `@synchronized`, a dedicated queue, or a `- Warning:` comment — and assume there is none until you have found it.

Known sharp edges:

- `BAInstallDataEditor` — `popOperationQueue` and the `operationQueue` getter mutate and copy without a lock; correctness depends on the caller holding one, which only `save:` does. `executeUserUpdateOperation` mutates `BAUserProfile` from the caller's thread, outside the shared queue, by design.
- `BAUserDataManager` — a method documents "we are not synchronizing here because we are on the shared queue, so this method is NOT thread-safe" as a comment; that comment is the whole contract.
- `BALocalCampaignsManager` — same shape: "this method is not thread safe: do not call it without some kind of lock".
- `BATaskDebouncer` — its header states that calling `schedule` across threads is unsupported. Give each caller its own debouncer rather than sharing one.
- `BAPromise` — declares itself "not thread-safe", and the guarding is asymmetric: `resolve:` and `then:` run under `@synchronized(_thenQueue)`, while `reject:` and `catch:` read and write `_status`, `_resolvedValue` and `_catchBlock` outside it. So the lock excludes nothing a rejection does: two `reject:` calls can both pass the `_status != Pending` guard and fire `_catchBlock` twice, and a `catch:` that reads `Pending` while `reject:` is installing the result stores a block nobody will ever call.
- SQLite datasources share neither a connection nor a queue, and they do not agree on locking: some call `sqlite3_open` and inherit the library default, `BAUserSQLiteDatasource` calls `sqlite3_open_v2` with `SQLITE_OPEN_FULLMUTEX` and carries a TODO to drop it once In-App JIT uses a shared queue. Read the open call in the datasource you are touching before assuming serialised access.
- Local campaigns keep a **pending-display balance**. `BALocalCampaignsCenter.displayInAppMessage:` calls `markCampaignAsPendingDisplay:` *before* handing the campaign to its output, because the display is asynchronous and the SQLite view counter is only incremented afterwards; `BALocalCampaignsManager.isCampaignOverCapping:ignoreMinInterval:` treats anything in that set as over-capped. Every terminal path must therefore unmark: success through `didPerformCampaignOutputWithIdentifier:eventData:`, and any non-display outcome through `didFailToDisplayCampaignOutputWithIdentifier:` — the outcomes wired to it today are the developer-delegate handoff, a failed `displayMessage:`, a background application state, and a pending message that was popped or superseded by Do Not Disturb (see the call sites in `BAMessagingCenter`). Add a new way for a display to not happen and you owe it an unmark: miss one and the campaign is silently over-capped for the rest of the process.
