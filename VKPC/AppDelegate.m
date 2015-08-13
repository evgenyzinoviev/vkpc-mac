//
//  AppDelegate.m
//  VKPC
//
//  Created by Eugene on 11/26/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "AppDelegate.h"
#import "Server.h"
#import "CatchMediaButtons.h"
#import "Controller.h"
//#import "HostsHack.h"
#import "Statistics.h"

#import "PopoverController.h"
#import "Popover.h"

static AppDelegate *shared;

@implementation AppDelegate

+ (AppDelegate *)shared {
    return shared;
}

- (void)awakeFromNib {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    shared = self;
    
    if (IsAnotherProcessRunning()) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error"];
        [alert setInformativeText:@"Another VKPC process is already running."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        
        [[NSApplication sharedApplication] terminate:nil];
        return;
    }
    
    // Init UI stuff
    [Popover shared];
    [PopoverController shared];
    
    // Preferences
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              VKPCPreferencesShowNotifications: [NSNumber numberWithBool:YES],
                                                              VKPCPreferencesInvertPlaylistIcons: [NSNumber numberWithBool:YES],
                                                              VKPCPreferencesCatchMediaButtons: [NSNumber numberWithBool:YES],
                                                              VKPCPreferencesBrowser: [NSNumber numberWithInt:0],
                                                              VKPCPreferencesStatisticReportedTimestamp: [NSNumber numberWithInt:0],
                                                              VKPCPreferencesUUID: @"",
                                                              VKPCPreferencesUseExtensionMode: [NSNumber numberWithBool:NO],
                                                              }];
    
    VKPCInitUUID();
    
    // Start catching (or not catching) media buttons
    [CatchMediaButtons initialize];
    
    // Usage reporting
    [Statistics initialize];
    
    [[PopoverController shared] setState:PopoverStatePlaylistNotLoaded];
    
    // Start server in a background thread
    [Server start];
    
    // Controller
    [Controller initialize];
}

@end
