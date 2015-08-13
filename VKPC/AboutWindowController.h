//
//  AboutWindowController.h
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WindowController.h"

@interface AboutWindowController : WindowController<NSWindowDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *titleTextField;
@property (weak) IBOutlet NSTextField *copyrightTextField;
@property (weak) IBOutlet NSTextField *ezTextField;
@property (weak) IBOutlet NSTextField *ch1pTextField;

//- (IBAction)sendEmailAction:(id)sender;

@end
