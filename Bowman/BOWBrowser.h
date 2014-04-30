//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <Foundation/Foundation.h>

#import <HyperBek/HyperBek.h>

@interface BOWBrowser : NSObject

- (NSString *)open:(NSURL *)url;
- (NSString *)look;
- (NSString *)go:(NSString *)rel index:(NSUInteger)index;
- (NSString *)back;

- (YBHALResource *)latestResource;

@end
