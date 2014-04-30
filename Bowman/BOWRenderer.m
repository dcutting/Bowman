//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import "BOWRenderer.h"

static NSUInteger IndentSize = 2;

@implementation BOWRenderer

- (NSString *)render:(YBHALResource *)resource {
    NSArray *result = [self render:resource depth:IndentSize];
    NSString *resourceStr = [result componentsJoinedByString:@"\n"];
    return [NSString stringWithFormat:@"%@\n", resourceStr];
}

- (NSArray *)render:(YBHALResource *)resource depth:(NSUInteger)depth {
    NSMutableArray *result = [NSMutableArray new];
    
    NSArray *renderedProperties = [self renderPropertiesForResource:resource];
    [self addRendered:renderedProperties title:@"Properties" depth:depth result:result];

    NSArray *renderedLinks = [self renderLinksForResource:resource];
    [self addRendered:renderedLinks title:@"Links" depth:depth result:result];

    NSArray *renderedEmbedded = [self renderEmbeddedForResource:resource];
    [self addRendered:renderedEmbedded title:@"Embedded" depth:depth result:result];

    return result;
}

- (NSArray *)renderPropertiesForResource:(YBHALResource *)resource {
    NSMutableArray *result = [NSMutableArray new];
    [resource.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isEqualToString:@"_links"] && ![key isEqualToString:@"_embedded"]) {
            NSString *propertyStr = [NSString stringWithFormat:@"%@: %@", key, obj];
            [result addObject:propertyStr];
        }
    }];
    return [result count] > 0 ? result : nil;
}

- (NSArray *)renderLinksForResource:(YBHALResource *)resource {
    NSMutableArray *result = [NSMutableArray new];
    [resource.links enumerateKeysAndObjectsUsingBlock:^(NSString *rel, NSArray *links, BOOL *stop) {
        [result addObject:[NSString stringWithFormat:@"%@", rel]];
        if ([links count] > 1) {
            [links enumerateObjectsUsingBlock:^(YBHALLink *link, NSUInteger idx, BOOL *stop) {
                [result addObject:[NSString stringWithFormat:@"  [%d] %@", (int)idx, link.href]];
            }];
        } else {
            [result addObject:[NSString stringWithFormat:@"  %@", [links[0] href]]];
        }
    }];
    return [result count] > 0 ? result : nil;
}

- (NSArray *)renderEmbeddedForResource:(YBHALResource *)resource {
    NSMutableArray *result = [NSMutableArray new];
    [resource.embedded enumerateKeysAndObjectsUsingBlock:^(NSString *rel, NSArray *embedded, BOOL *stop) {
        [embedded enumerateObjectsUsingBlock:^(YBHALResource *embeddedResource, NSUInteger idx, BOOL *stop) {
            [result addObject:[NSString stringWithFormat:@"+ %@ [%d]", rel, (int)idx]];
            [result addObjectsFromArray:[self render:embeddedResource depth:IndentSize]];
        }];
    }];
    return [result count] > 0 ? result : nil;
}

- (void)addRendered:(NSArray *)rendered title:(NSString *)title depth:(NSUInteger)depth result:(NSMutableArray *)result {
    if (!rendered) return;
    NSString *augmentedTitle = [NSString stringWithFormat:@"[%@]", title];
    [result addObject:[self indent:augmentedTitle depth:depth]];
    [rendered enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:[self indent:obj depth:depth + IndentSize]];
    }];
}

- (NSString *)indent:(NSString *)str depth:(NSUInteger)depth {
    NSMutableString *indented = [NSMutableString new];
    for (NSUInteger i = 0; i < depth; i++) {
        [indented appendString:@" "];
    }
    [indented appendString:str];
    return indented;
}

@end
