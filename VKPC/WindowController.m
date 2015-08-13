//
//  WindowController.m
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "WindowController.h"

@implementation WindowController {
    id eventMonitor;
    BOOL eventMonitorSet;
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)allowsClosingWithShortcut {
    return NO;
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    if ([self allowsClosingWithShortcut] && !eventMonitorSet) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:self.window];
        
        // Close window on esc or cmd+w
        NSEvent *(^handler)(NSEvent *) = ^(NSEvent *theEvent) {
            NSWindow *targetWindow = theEvent.window;
            if (targetWindow != self.window) {
                return theEvent;
            }
            
            NSEvent *result = theEvent;
            if (theEvent.keyCode == 53 || ( theEvent.keyCode == 13 && [theEvent modifierFlags] & NSCommandKeyMask )) {
                [self.window close];
            }
            
            return result;
        };
        
        eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:handler];
        eventMonitorSet = YES;
    }
}

- (void)windowDidLoad {
    eventMonitorSet = NO;
    [super windowDidLoad];
}

- (void)windowWillClose:(NSNotification *)notification {
    // [NSEvent removeMonitor:eventMonitor];
}


@end
