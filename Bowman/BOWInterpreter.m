//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import "BOWInterpreter.h"

@implementation BOWInterpreter

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
    printf("> ");
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
    return line;
}

- (void)showResult:(NSString *)result {
    printf("%s\n", [result cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showNewline {
    printf("\n");
}

@end
