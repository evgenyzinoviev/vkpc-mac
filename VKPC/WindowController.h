//
//  WindowController.h
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController<NSWindowDelegate>

@property (strong) IBOutlet NSWindow *window;

- (void)windowWillClose:(NSNotification *)notification;
- (BOOL)allowsClosingWithShortcut;

@end
