//
//  HostsHack.m
//  VKPC
//
//  Created by Eugene on 10/30/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "HostsHack.h"
#import "HostsHackWindowController.h"
#import "AppDelegate.h"

#include <stdio.h>

#ifdef DEBUG
#include <time.h>
#endif

NSString * const VKPCHostsHackTaskFinished = @"VKPCHostsHackTaskFinished";

static BOOL hackFound = NO;
static HostsHackWindowController *windowController = nil;
#ifdef DEBUG
static char *testPath = "/tmp/vkpc_test";
#endif

@implementation HostsHack

static NSString *readLineASNSString(FILE *file) {
    char *line = NULL;
    size_t len = 0;
    getline(&line, &len, file);
    return [NSString stringWithUTF8String:line];
}

+ (void)check {
    hackFound = NO;
    
#ifdef DEBUG
    clock_t begin = clock();
#endif
    
    FILE *file = fopen(VKPCHostsFile, "r");
    if (file == NULL) {
        NSLog(@"[HostsHack check] !file, returning");
        return;
    }
    
    while (!feof(file)) {
        NSString *line = readLineASNSString(file);
//        NSLog(@"[hostshack] line: %@", line);
        NSRange rng = [line rangeOfString:[NSString stringWithUTF8String:VKPCWSClientHost]];
        if (rng.location != NSNotFound) {
//        if ([line containsString:[NSString stringWithUTF8String:VKPCWSClientHost]]) {
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([line hasPrefix:@"127.0.0.1"]) {
                hackFound = YES;
                break;
            }
        }
    }
    fclose(file);
    
#ifdef DEBUG
    NSLog(@"[HostsHack check] file reading time: %lf", (double)(clock() - begin) / CLOCKS_PER_SEC);
    NSLog(@"[HostsHack check] found: %s", hackFound ? "YES" : "NO");
#endif
}

static void showAlert(NSString *text, NSString *informativeText) {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:text];
    [alert setInformativeText:informativeText];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

+ (void)hack {
//    return;
    
    AuthorizationRef auth = NULL;
    OSStatus err;
    
    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagInteractionAllowed, &auth);
    if (err != errAuthorizationSuccess) {
        showAlert(@"VKPC Error", [NSString stringWithFormat:@"Failed to obtain authorization. Code = %d", err]);
        [windowController setButtonRetry];
        return;
    }
    
    const char *path = [[NSProcessInfo processInfo].arguments[0] UTF8String];
    char * const args[] = {"--hostshack", NULL};
    
    [windowController setButtonWait];
    
    err = AuthorizationExecuteWithPrivileges(auth, path, kAuthorizationFlagDefaults, args, NULL);
    if (err != errAuthorizationSuccess) {
        showAlert(@"VKPC Error", [NSString stringWithFormat:@"Failed to run command with adminstrative privileges. Code = %d", err]);
        [windowController setButtonRetry];
        return;
    }
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:(id)[self class]
                                                        selector:@selector(hackTaskFinished:)
                                                            name:VKPCHostsHackTaskFinished
                                                          object:nil];
}

+ (void)hackTaskFinished:(id)notification {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:(id)[self class]];
    
    [self check];
    
    if (hackFound) {
        [windowController close];
        [[AppDelegate shared] continueRunning];
    } else {
        [self showUnableAlert];
    }
}

+ (void)showUnableAlert {
    showAlert(@"VKPC Error", [NSString stringWithFormat:
                                         @"Unfortunately, VKPC failed to automatically edit the file %@. Now you have to make it manually.\n\n"
                                         "Please open the file %@ with root privileges and add following line at the end:\n\n"
                                         "127.0.0.1\t%@\n\n"
                                         "Then save the file and relaunch the app.",
                                         [NSString stringWithUTF8String:VKPCHostsFile],
                                         [NSString stringWithUTF8String:VKPCHostsFile],
                                         [NSString stringWithUTF8String:VKPCWSClientHost]]);
}

+ (int)doHack {
//    sleep(2);
    
    char *path = VKPCHostsFile;
    FILE *file = fopen(path, "a");
    if (!file) {
        NSLog(@"[HostsHack doHack] error opening file %s, returning error", path);
        return -1;
    }
    
    fputs("\n#VK Player Controller", file);
    fputs([[NSString stringWithFormat:@"\n127.0.0.1\t%@", [NSString stringWithUTF8String:VKPCWSClientHost]] UTF8String], file);
    
    fclose(file);
    return 0;
}

+ (BOOL)found {
    return hackFound;
}

+ (void)showWindow {
    if (!windowController) {
        windowController = [[HostsHackWindowController alloc] initWithWindowNibName:@"HostsHackWindow"];
    }
    [windowController showWindow:nil];
    [windowController.window makeKeyAndOrderFront:nil];
    [windowController.window setLevel:kCGFloatingWindowLevel];
}

@end
