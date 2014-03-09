//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import "BOWRenderer.h"

@implementation BOWRenderer

- (NSString *)render:(YBHALResource *)resource {
    NSMutableString *result = [NSMutableString new];
    [result appendFormat:@"You are at: %@\n", resource.baseURL];
    [result appendString:@"  Links:\n"];
    [resource.links enumerateKeysAndObjectsUsingBlock:^(NSString *rel, NSArray *links, BOOL *stop) {
        [links enumerateObjectsUsingBlock:^(YBHALLink *link, NSUInteger idx, BOOL *stop) {
            [result appendFormat:@"  - %@: %@\n", rel, link];
        }];
    }];
    [result appendString:@"  Embedded:\n"];
    [resource.embedded enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result appendFormat:@"  - %@: %@\n", key, obj];
    }];
    return result;
}

@end
