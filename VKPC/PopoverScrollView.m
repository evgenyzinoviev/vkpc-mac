//
//  PopoverScrollView.m
//  VKPC
//
//  Created by Eugene on 11/3/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "PopoverScrollView.h"
#import "PopoverClipView.h"

@implementation PopoverScrollView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self == nil) return nil;
    
    [self swapClipView];
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (![self.contentView isKindOfClass:PopoverClipView.class] ) {
        [self swapClipView];
    }
}

- (void)swapClipView {
    self.wantsLayer = YES;
    id documentView = self.documentView;
    PopoverClipView *clipView = [[PopoverClipView alloc] initWithFrame:self.contentView.frame];
    self.contentView = clipView;
    self.documentView = documentView;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)wantsLayer {
    return YES;
}

@end
