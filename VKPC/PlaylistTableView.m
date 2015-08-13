//
//  PlaylistTableView.m
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "PlaylistTableView.h"
#import "Global.h"
#import "PlaylistTableRowView.h"
#import "PlaylistTableController.h"

static const int kRowHeight = 51;

@implementation PlaylistTableView {
    NSInteger pressedRow;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self.enclosingScrollView setDrawsBackground:NO];
        [self.enclosingScrollView setBorderType:NSNoBorder];
        [self setHeaderView:nil];
        [self setBackgroundColor:[NSColor clearColor]];
        
        pressedRow = -1;
    }
    return self;
}

- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
}

//- (BOOL)wantsLayer {
//    return YES;
//}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:point];
    
    if (row != -1) {
        pressedRow = row;
        PlaylistTableRowView *rowView = [self rowViewAtRow:row makeIfNecessary:NO];
        rowView.mouseInside = YES;
        [rowView setTrackSelected:YES];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:point];
    
    if (row != -1 && (int)row == pressedRow) {
        PlaylistTableRowView *rowView = [self rowViewAtRow:row makeIfNecessary:NO];
        [rowView setTrackSelected:NO];
        
        [_controller selectedRowAtIndex:(int)row];
    }
}

- (int)getContentSize {
    return kRowHeight * (int)[self numberOfRows];
}

@end
