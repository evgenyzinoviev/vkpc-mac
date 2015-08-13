//
//  HostsHackWindowController.h
//  VKPC
//
//  Created by Eugene on 10/30/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WindowController.h"
#import "FlippedView.h"

//@class FlippedView;

@interface HostsHackWindowController : WindowController<NSWindowDelegate>

//@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *configurationRequiredTextField;
@property (weak) IBOutlet NSButton *button;

- (IBAction)buttonPressed:(id)sender;
- (void)setButtonRetry;
- (void)setButtonContinue;
- (void)setButtonWait;

@end
