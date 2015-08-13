//
//  ShadowTextFieldCell.m
//  VKPC
//
//  Created by Eugene on 12/2/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "ShadowTextFieldCell.h"

static NSShadow *kShadow = nil;

@implementation ShadowTextFieldCell

+ (void)initialize {
    if (!VKPCIsYosemite) {
        kShadow = [[NSShadow alloc] init];
        [kShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.f alpha:0.85f]];
        [kShadow setShadowBlurRadius:0.f];
        [kShadow setShadowOffset:NSMakeSize(0.f, -1.f)];
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (!VKPCIsYosemite) {
        [kShadow set];
    }
    [super drawInteriorWithFrame:cellFrame inView:controlView];
    
//    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.0] set];
//    NSRectFillUsingOperation(cellFrame, NSCompositeSourceOver);
}

- (BOOL)isOpaque {
    return NO;
}

@end
