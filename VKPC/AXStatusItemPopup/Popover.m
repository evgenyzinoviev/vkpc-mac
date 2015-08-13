//
//  Created by Alexander Schuch on 06/03/13.
//  Modified by Eugene Zinoviev on 12/03/13.
//  Copyright (c) 2013 Alexander Schuch. All rights reserved.
//  Copyright (c) 2013-2014 Eugene Zinoviev. All rights reserved.
//

#import "Popover.h"
#import "PopoverImageView.h"

static const int kMinViewWidth = 28;

@implementation Popover {
    PopoverImageView *imageView;
    id popoverTransiencyMonitor;
    BOOL popoverTransiencyMonitorEnabled;
//    BOOL firstDrawed;
//    id eventMonitor;
//    BOOL escMonitorSet;
}

+ (id)shared {
    static Popover *shared = nil;
    @synchronized (self) {
        if (shared == nil){
            shared = [[self alloc] init];
        }
    }
    return shared;
}

- (id)init {
    popoverTransiencyMonitorEnabled = NO;
//    firstDrawed = NO;
    CGFloat height = [NSStatusBar systemStatusBar].thickness;
    _active = NO;
//    escMonitorSet = NO;
    
    if (self = [super initWithFrame:NSMakeRect(0, 0, kMinViewWidth, height)]) {
        imageView = [[PopoverImageView alloc] initWithFrame:NSMakeRect(0, 0, kMinViewWidth, height)];
        [self addSubview:imageView];
        
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        _statusItem.view = self;
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//            [self showPopover];
//        });
    }
    return self;
}

- (BOOL)allowsVibrancy {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
//    if (!firstDrawed) {
//        firstDrawed = YES;
//        [self showPopover];
//    }
    
    if (_active) {
        [[NSColor selectedMenuItemColor] setFill];
    } else {
        [[NSColor clearColor] setFill];
    }
    NSRectFill(dirtyRect);
    
    NSDictionary *images = VKPCGetImagesDictionary();
    NSImage *imgDefault = images[VKPCImageStatus], *imgActive = images[VKPCImageStatusPressed];
    imageView.image = _active ? imgActive : imgDefault;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (_popover.isShown) {
        [self hidePopover];
    } else {
        [self showPopover];
    }
}

- (void)setActive:(BOOL)active {
    _active = active;
    [self setNeedsDisplay:YES];
}

- (void)updateViewFrame {
    CGFloat width = MAX(MAX(kMinViewWidth, _altImage.size.width), _defaultImage.size.width);
    CGFloat height = [NSStatusBar systemStatusBar].thickness;
    
    NSRect frame = NSMakeRect(0, 0, width, height);
    self.frame = frame;
    imageView.frame = frame;
    
    [self setNeedsDisplay:YES];
}

- (void)showPopover {
    self.active = YES;
    
    if (!_popover) {
        _popover = [[NSPopover alloc] init];
        _popover.contentViewController = [PopoverController shared];
        
//        NSEvent *(^handler)(NSEvent *) = ^NSEvent *(NSEvent *theEvent) {
//            if (theEvent.keyCode == 53) {
//                NSLog(@"[Popover] catch ESC");
//                return nil;
//            }
//
//            return theEvent;
//        };
//        
//        eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:handler];
        
    };
    
    if (!_popover.isShown) {
        _popover.animates = NO;
        [_popover showRelativeToRect:self.frame ofView:self preferredEdge:NSMinYEdge];
        if (!popoverTransiencyMonitorEnabled) {
            popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent* event) {
                [self hidePopover];
            }];
            popoverTransiencyMonitorEnabled = YES;
        }
    }
    
    [[PopoverController shared] popoverDidShow];
}

- (void)hidePopover {
    self.active = NO;
    
    if (_popover && _popover.isShown) {
        [_popover close];
        [[PopoverController shared] popoverDidHide];
        if (popoverTransiencyMonitorEnabled) {
            [NSEvent removeMonitor:popoverTransiencyMonitor];
            popoverTransiencyMonitorEnabled = NO;
        }
    }
}

- (NSSize)getSize {
    return [_popover contentSize];
}

- (void)setSize:(NSSize)size animate:(BOOL)animate {
    BOOL bkAnimates = _popover.animates;
    _popover.animates = animate;
    [_popover setContentSize:size];
    _popover.animates = bkAnimates;
}

@end






