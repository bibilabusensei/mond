//
//  GestaltAccess.h
//  GestaltEdit
//
//  High-level service that uses bad_query to acquire a read/write sandbox
//  extension, then reads and saves com.apple.MobileGestalt.plist.
//  Source: https://github.com/frs0n/GestaltEdit
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GestaltAccess : NSObject

+ (instancetype)shared;
+ (BOOL)isRunningSupportedOS;
+ (NSString *)currentOSBuild;
- (BOOL)connectWithError:(NSError **)error;
- (nullable NSDictionary *)readGestaltWithError:(NSError **)error;
- (nullable NSData *)readGestaltDataWithError:(NSError **)error;
- (BOOL)saveGestalt:(NSDictionary *)plist error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
