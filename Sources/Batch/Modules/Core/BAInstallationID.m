#import <Batch/BAInstallationID.h>

#import <Batch/BALogger.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BAAESB64Cryptor.h>
#import <Batch/BADirectories.h>
#import <Batch/BAParameter.h>

@implementation BAInstallationID

+ (nullable NSString*)installationID
{
    if ([[BAOptOut instance] isOptedOut]) {
        return nil;
    }
    
    // Look into shared prefs, and then try to recover from file
    NSString *di = [BAParameter objectForKey:kParametersLocalInstallIdentifierKey fallback:nil];
    if (![BANullHelper isStringEmpty:di])
    {
        return [di uppercaseString];
    }
    
    // Fallback on the file
    NSString *path = [self filePersistencePath];
    di = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    BAAESB64Cryptor *cryptor = [[BAAESB64Cryptor alloc] initWithKey:[NSString stringWithFormat:@"%@XpBXC%iH",BAPrivateKeyStorage,58]];
    if (![BANullHelper isStringEmpty:di])
    {
        di = [cryptor decrypt:di];
    }
    
    if (![BANullHelper isStringEmpty:di])
    {
        // Save the recovered di in the shared user prefs
        [BAParameter setValue:di forKey:kParametersLocalInstallIdentifierKey saved:YES];
        return [di uppercaseString];
    }
    
    // No Install ID found: make one
    NSString *newID = [[NSUUID UUID].UUIDString uppercaseString];
    
    // Save this parameter to shared prefs AND a file backup
    [BAParameter setValue:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forKey:kParametersLocalInstallDateIdentifierKey saved:YES];
    
    [BAParameter setValue:newID forKey:kParametersLocalInstallIdentifierKey saved:YES];
    [[cryptor encrypt:newID] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];

    return newID;
}

+ (void)delete
{
    [BAParameter removeObjectForKey:kParametersLocalInstallIdentifierKey];
    NSError *err = nil;
    NSString *path = [self filePersistencePath];
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&err]) {
        [BALogger debugForDomain:@"BAInstallationID" message:@"Could not delete install ID file (path: %@): %@", path, err.localizedDescription];
    }
}

+ (NSString*)filePersistencePath
{
    return [[BADirectories pathForBatchAppSupportDirectory] stringByAppendingPathComponent:[BABundleIdentifier stringByAppendingString:@".plist"]];
}

@end
