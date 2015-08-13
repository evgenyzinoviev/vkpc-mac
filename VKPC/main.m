//
//  main.m
//  VKPC
//
//  Created by Eugene on 11/26/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Global.h"
//#import "HostsHack.h"

#include <string.h>
#include <unistd.h>
#include <signal.h>

//int doHostsHack() {
//    if (geteuid() != 0) {
//        NSLog(@"Run as root to hack hosts");
//        return -2;
//    }
//    
//    [HostsHack doHack];
//    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: VKPCHostsHackTaskFinished object:nil userInfo:nil deliverImmediately:YES];
//    
//    return 0;
//}

int main(int argc, const char * argv[]) {
    VKPCInitGlobals();
    signal(SIGPIPE, SIG_IGN);
    
//    if (argc > 1) {
//        for (int i = 1; i < argc; i++) {
//            if (strcmp(argv[i], "--hostshack") == 0) {
//                return doHostsHack();
//            }
//        }
//    }
    
    return NSApplicationMain(argc, argv);
}