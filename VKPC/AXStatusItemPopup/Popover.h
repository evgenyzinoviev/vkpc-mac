//
//  Created by Alexander Schuch on 06/03/13.
//  Modified by Eugene Zinoviev on 12/03/13.
//  Copyright (c) 2013 Alexander Schuch. All rights reserved.
//  Copyright (c) 2013-2014 Eugene Zinoviev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "PopupControllerProtocol.h"
#import "PopoverController.h"

@interface Popover : NSView

@property(assign, nonatomic, getter=isActive) BOOL active;
@property(strong, nonatomic) NSImage *defaultImage;
@property(strong, nonatomic) NSImage *altImage;
@property(strong, nonatomic) NSImage *flatImage;
@property(strong, nonatomic) NSStatusItem *statusItem;
@property(strong) NSPopover *popover;

+ (id)shared;
- (id)init;

- (void)showPopover;
- (void)hidePopover;

- (NSSize)getSize;
- (void)setSize:(NSSize)size animate:(BOOL)animate;

@end
