//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <HyperBek/HyperBek.h>

#import "BOWBrowser.h"
#import "BOWRenderer.h"

@interface BOWBrowser ()

@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, strong) BOWRenderer *renderer;

@end

@implementation BOWBrowser

- (id)init {
    self = [super init];
    if (self) {
        _history = [NSMutableArray new];
        _renderer = [BOWRenderer new];
    }
    return self;
}

- (NSString *)open:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
    if (!data) return nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    YBHALResource *resource = [[YBHALResource alloc] initWithDictionary:json baseURL:url];
    [self pushResource:resource];
    return [self look];
}

- (NSString *)look {
    YBHALResource *resource = [self latestResource];
    if (!resource) return nil;
    return [self.renderer render:resource];
}

- (void)pushResource:(YBHALResource *)resource {
    [self.history addObject:resource];
}

- (YBHALResource *)latestResource {
    return [self.history count] > 0 ? [self.history lastObject] : nil;
}

- (NSString *)go:(NSString *)rel index:(NSUInteger)index {
    NSArray *links = [[self latestResource] linksForRelation:rel];
    if (links) {
        if (index >= [links count]) return nil;
        YBHALLink *link = links[index];
        return [self open:link.URL];
    } else {
        NSArray *resources = [[self latestResource] resourcesForRelation:rel];
        if (index >= [resources count]) return nil;
        YBHALResource *resource = resources[index];
        [self pushResource:resource];
        return [self look];
    }
}

- (NSString *)back {
    if ([self.history count] > 1) {
        [self.history removeLastObject];
    }
    return [self look];
}

@end
