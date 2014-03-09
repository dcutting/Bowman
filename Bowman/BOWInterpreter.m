//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import "BOWBrowser.h"
#import "BOWInterpreter.h"

@interface BOWInterpreter ()

@property (nonatomic, strong) BOWBrowser *browser;

@end

@implementation BOWInterpreter

- (id)init {
    self = [super init];
    if (self) {
        _browser = [BOWBrowser new];
    }
    return self;
}

- (void)start {
    while (YES) {
        [self showPrompt];
        NSString *line = [self readLine];
        if (!line) break;
        NSString *result = [self interpretLine:line];
        [self showResult:result];
    }
    [self showNewline];
}

- (void)showPrompt {
    printf("$ ");
}

- (NSString *)readLine {
    char buf[1000];
    if (fgets(buf, sizeof buf, stdin)) {
        *strchr(buf, '\n') = '\0';
        return [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSString *)interpretLine:(NSString *)line {
    NSArray *words = [self extractWords:line];
    if (!words) return nil;

    NSString *command = [self extractCommand:words];
    NSArray *arguments = [self extractArguments:words];

    NSString *result = [self interpretCommand:command arguments:arguments];
    
    return result ? result : @"*** Error\n";
}

- (NSArray *)extractWords:(NSString *)line {
    NSArray *words = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [words count] > 0 ? words : nil;
}

- (NSString *)extractCommand:(NSArray *)words {
     return [words firstObject];
}

- (NSArray *)extractArguments:(NSArray *)words {
    NSArray *arguments;
    if ([words count] > 1) {
        arguments = [words subarrayWithRange:NSMakeRange(1, [words count] - 1)];
    }
    return arguments;
}

- (NSString *)interpretCommand:(NSString *)command arguments:(NSArray *)arguments {
    if ([command isEqualToString:@"open"] || [command isEqualToString:@"o"]) {
        return [self open:arguments];
    } else if ([command isEqualToString:@"look"] || [command isEqualToString:@"l"]) {
        return [self look];
    } else if ([command isEqualToString:@"go"] || [command isEqualToString:@"g"]) {
        return [self go:arguments];
    } else if ([command isEqualToString:@"back"] || [command isEqualToString:@"b"]) {
        return [self back];
    }
    return nil;
}

- (NSString *)open:(NSArray *)arguments {
    NSString *urlStr = [arguments firstObject];
    NSURL *url = [NSURL URLWithString:urlStr];
    return [self.browser open:url];
}

- (NSString *)look {
    return [self.browser look];
}

- (NSString *)go:(NSArray *)arguments {
    NSString *rel = [arguments firstObject];
    return [self.browser go:rel];
}

- (NSString *)back {
    return [self.browser back];
}

- (void)showResult:(NSString *)result {
    printf("\n%s\n", [result cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showNewline {
    printf("\n");
}

@end
