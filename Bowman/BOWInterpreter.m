//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <readline/readline.h>

#import "BOWBrowser.h"
#import "BOWInterpreter.h"

static char *line_read = (char *)NULL;

sigjmp_buf ctrlc_buf;

void handle_signal(int signo) {
    if (signo == SIGINT) {
        printf("^C\n");
        siglongjmp(ctrlc_buf, 1);
    }
}

char *rl_gets(NSString *prompt) {
    if (line_read) {
        free(line_read);
        line_read = (char *)NULL;
    }
    line_read = readline([prompt cStringUsingEncoding:NSUTF8StringEncoding]);
    if (line_read && *line_read) {
        add_history(line_read);
    }
    return line_read;
}

@interface BOWInterpreter ()

@property (nonatomic, strong) BOWBrowser *browser;

@end

@implementation BOWInterpreter

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _browser = [BOWBrowser new];
        NSString *result = [self.browser open:url];
        if (result) {
            [self showResult:result];
        } else {
            return nil;
        }
    }
    signal(SIGINT, handle_signal);
    return self;
}

- (void)start {
    while (sigsetjmp(ctrlc_buf, 1) != 0);
    while (YES) {
        NSString *line = [self readLine];
        if (!line) break;
        NSString *result = [self interpretLine:line];
        if (result) {
            [self showResult:result];
        }
    }
    [self showNewline];
}

- (NSString *)readLine {
    NSString *url = [[self.browser latestResource].baseURL absoluteString];
    if (!url) url = @"";
    NSString *prompt = [NSString stringWithFormat:@"%@:$ ", url];
    char *cLine = rl_gets(prompt);
    if (!cLine) return nil;
    NSString *line = [NSString stringWithCString:cLine encoding:NSUTF8StringEncoding];
    line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return line;
}

- (NSString *)interpretLine:(NSString *)line {
    NSArray *words = [self extractWords:line];
    if (!words) return nil;

    NSString *command = [self extractCommand:words];
    if ([command isEqualToString:@""]) return nil;
    NSArray *arguments = [self extractArguments:words];

    NSString *result = [self interpretCommand:command arguments:arguments ];
    
    return result ? result : @"* Error\n";
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
    if ([command isEqualToString:@"look"] || [command isEqualToString:@"l"]) {
        return [self look];
    } else if ([command isEqualToString:@"go"] || [command isEqualToString:@"get"] || [command isEqualToString:@"g"]) {
        return [self go:arguments];
    } else if ([command isEqualToString:@"back"] || [command isEqualToString:@"b"]) {
        return [self back];
    } else if ([command isEqualToString:@"post"] || [command isEqualToString:@"p"]) {
        return [self post:arguments];
    }
    return nil;
}

- (NSString *)look {
    return [self.browser look];
}

- (NSString *)go:(NSArray *)arguments {
    NSString *rel = [arguments firstObject];
    NSUInteger argumentIndex = 1;
    NSUInteger index = NSNotFound;
    if ([arguments count] > argumentIndex) {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *number = [formatter numberFromString:arguments[argumentIndex]];
        if (number) {
            index = [number integerValue];
            argumentIndex++;
        }
    }
    NSDictionary *variables;
    if ([arguments count] > argumentIndex) {
        NSMutableArray *remainderArguments = [arguments mutableCopy];
        [remainderArguments removeObjectsInRange:NSMakeRange(0, argumentIndex)];
        NSString *variableArgument = [remainderArguments componentsJoinedByString:@" "];
        variables = [self extractVariables:variableArgument];
    }
    return [self.browser go:rel index:index variables:variables];
}

- (NSDictionary *)extractVariables:(NSString *)argument {
    NSData *data = [argument dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
}

- (NSString *)post:(NSArray *)arguments {
    NSString *rel = [arguments firstObject];
    if ([arguments count] <= 1) return nil;
    NSString *body = [arguments objectAtIndex:1];
    return [self.browser post:rel body:body];
}

- (NSString *)back {
    return [self.browser back];
}

- (void)showResult:(NSString *)result {
    printf("%s", [result cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showNewline {
    printf("\n");
}

@end
