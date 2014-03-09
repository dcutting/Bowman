//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <Foundation/Foundation.h>

@interface BOWBrowser : NSObject

- (NSString *)load:(NSURL *)url;
- (NSString *)look;
- (NSString *)go:(NSString *)rel;
- (NSString *)back;

@end
