//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <Foundation/Foundation.h>

#import "BOWInterpreter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc != 2) {
            printf("Usage: %s <URL>\n", argv[0]);
            return 1;
        }
        const char *cArg = argv[1];
        NSString *arg = [NSString stringWithCString:cArg encoding:NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:arg];
        BOWInterpreter *interpreter = [[BOWInterpreter alloc] initWithURL:url];
        [interpreter start];
    }
    return 0;
}
