//
//  PopoverClipView.m
//  VKPC
//
//  Created by Eugene on 11/3/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "PopoverClipView.h"
#import <QuartzCore/QuartzCore.h>

@implementation PopoverClipView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (!self) return nil;
    
    self.layer = [CAScrollLayer layer];
    self.wantsLayer = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)wantsLayer {
    return YES;
}

@end
