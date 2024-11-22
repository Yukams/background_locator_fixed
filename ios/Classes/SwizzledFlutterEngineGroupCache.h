#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <Flutter/FlutterEngineGroup.h>

@interface SwizzledFlutterEngineGroupCache : NSObject

+ (instancetype)sharedInstance;
- (FlutterEngineGroup *)get:(NSString *)key;
- (void)put:(NSString *)key engineGroup:(FlutterEngineGroup *)engineGroup;

@end
