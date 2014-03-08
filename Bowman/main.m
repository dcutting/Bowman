//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <Foundation/Foundation.h>

#import "BOWInterpreter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        BOWInterpreter *interpreter = [BOWInterpreter new];
        [interpreter start];
    }
    return 0;
}
