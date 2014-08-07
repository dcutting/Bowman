//  Copyright (c) 2014 Yellowbek. All rights reserved.

#import <readline/readline.h>

#import "BOWBrowser.h"
#import "BOWInterpreter.h"

static char *line_read = (char *)NULL;

sigjmp_buf ctrlc_buf;

BOWInterpreter *interpreter;

@interface BOWInterpreter ()

@property (nonatomic, strong) BOWBrowser *browser;

- (NSArray *)relsForText:(NSString *)text;

@end

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

typedef struct {
    char *name;			/* User printable name of the function. */
    char *doc;			/* Documentation for this function.  */
} COMMAND;

COMMAND commands[] = {
    { "look", "Display the current resource" },
    { "get", "Follow a link relation" },
    { "go", "Synonym for get" },
    { "post", "POST to a link relation" },
    { "back", "Go back" },
    { "set", "Set a header to be used in subsequent requests" },
    { "help", "Display help" },
    { (char *)NULL, (char *)NULL }
};

char *dupstr(char *s) {
    char *r;
    r = malloc(strlen(s) + 1);
    strcpy(r, s);
    return r;
}

char *command_generator(char *text, int state) {
    static int list_index;
    static size_t len;
    char *name;

    /* If this is a new word to complete, initialize now.  This includes
     saving the length of TEXT for efficiency, and initializing the index
     variable to 0. */
    if (!state) {
        list_index = 0;
        len = strlen(text);
    }

    /* Return the next name which partially matches from the command list. */
    while ((name = commands[list_index].name)) {
        list_index++;
        if (strncmp(name, text, len) == 0) {
            return dupstr(name);
        }
    }

    /* If no names matched, then return NULL. */
    return ((char *)NULL);
}

char *rel_generator(char *text, int state) {
    static int list_index;
    static size_t len;

    /* If this is a new word to complete, initialize now.  This includes
     saving the length of TEXT for efficiency, and initializing the index
     variable to 0. */
    if (!state) {
        list_index = 0;
        len = strlen(text);
    }

    /* Return the next name which partially matches from the command list. */
    NSString *textStr = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
    NSArray *rels = [interpreter relsForText:textStr];

    while (list_index < [rels count]) {
        NSString *rel = rels[list_index];
        list_index++;
        char *relC = (char *)[rel cStringUsingEncoding:NSUTF8StringEncoding];
        return dupstr(relC);
    }

    /* If no names matched, then return NULL. */
    return ((char *)NULL);
}

char **bowman_completion(char *text, int start, int end) {
    char **matches = (char **)NULL;

    /* If this word is at the start of the line, then it is a command
     to complete.  Otherwise it is the name of a file in the current
     directory. */
    if (start == 0) {
        matches = completion_matches(text, (CPFunction *)command_generator);
    } else {
        matches = completion_matches(text, (CPFunction *)rel_generator);
    }
    return matches;
}

char **empty_completion(char *text, int start, int end) {
    return NULL;
}

@implementation BOWInterpreter

- (NSArray *)relsForText:(NSString *)text {
    NSMutableArray *rels = [NSMutableArray new];
    NSDictionary *links = self.browser.latestResource.links;
    [self addRelsTo:rels text:text links:links];
    NSDictionary *embedded = self.browser.latestResource.embedded;
    [self addRelsTo:rels text:text links:embedded];
    return rels;
}

- (void)addRelsTo:(NSMutableArray *)rels text:(NSString *)text links:(NSDictionary *)links {
    [links enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        NSRange range = [key rangeOfString:text];
        if ([text isEqualToString:@""] || NSNotFound != range.location) {
            [rels addObject:key];
        }
    }];
}

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
    rl_attempted_completion_function = (CPPFunction *)bowman_completion;
    rl_completion_entry_function = (Function *)empty_completion;
    interpreter = self;
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
    NSString *methodName = [NSString stringWithFormat:@"command_%@:", command];
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        NSString *(*func)(id, SEL, NSArray *) = (void *)imp;
        NSString *result = func(self, selector, arguments);
        return result;
    }
    return nil;
}

- (NSString *)command_look:(NSArray *)arguments {
    return [self.browser look];
}

- (NSString *)command_go:(NSArray *)arguments {
    return [self command_get:arguments];
}

- (NSString *)command_get:(NSArray *)arguments {
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

- (NSString *)command_post:(NSArray *)arguments {
    NSString *rel = [arguments firstObject];
    if ([arguments count] <= 1) return nil;
    NSString *body = [arguments objectAtIndex:1];
    return [self.browser post:rel body:body];
}

- (NSString *)command_set:(NSArray *)arguments {
    if ([arguments count] < 1) {
        return [self.browser showHeaders];
    }
    NSString *headerName = [arguments objectAtIndex:0];
    NSString *headerValue;
    if ([arguments count] > 1) {
        NSMutableArray *remainderArguments = [arguments mutableCopy];
        [remainderArguments removeObjectAtIndex:0];
        headerValue = [remainderArguments componentsJoinedByString:@" "];
    }
    return [self.browser setHeader:headerName value:headerValue];
}

- (NSString *)command_back:(NSArray *)arguments {
    return [self.browser back];
}

- (NSString *)command_help:(NSArray *)arguments {
    NSMutableString *help = [NSMutableString new];
    for (NSInteger i = 0; i < sizeof(commands)/sizeof(COMMAND); i++) {
        COMMAND command = commands[i];
        if (command.name) {
            [help appendFormat:@"%s: %s\n", command.name, command.doc];
        }
    }
    return help;
}

- (void)showResult:(NSString *)result {
    printf("%s", [result cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)showNewline {
    printf("\n");
}

@end
