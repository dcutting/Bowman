//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <Foundation/Foundation.h>

#import <HyperBek/HyperBek.h>

@interface BOWBrowser : NSObject

- (NSString *)open:(NSURL *)url;
- (NSString *)look;
- (NSString *)go:(NSString *)rel index:(NSUInteger)index variables:(NSDictionary *)variables;
- (NSString *)post:(NSString *)rel body:(NSString *)body;
- (NSString *)delete:(NSString *)rel;
- (NSString *)setHeader:(NSString *)name value:(NSString *)value;
- (NSString *)showHeaders;
- (NSString *)back;

- (YBHALResource *)latestResource;

@end
