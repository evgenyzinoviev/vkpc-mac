//
//  PlaylistTableRowView.m
//  VKPC
//
//  Created by Eugene on 12/2/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//  TODO иногда не реагирует на нажатия; найти и исправить
//  TODO проблемы с ретиной! исправить
//  TODO выяснить, актуальны ли предыдущие TODO

#import "PlaylistTableRowView.h"

@implementation PlaylistTableRowView {
    BOOL _trackSelected;
    BOOL _everSelected;
    NSTrackingArea *trackingArea;
}

//@dynamic _mouseInside;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _everSelected = NO;
    }
    return self;
}

- (void)setMouseInside:(BOOL)mouseInside {
    if (_mouseInside != mouseInside) {
        _mouseInside = mouseInside;
        if (_trackSelected) {
            [self setNeedsDisplay:YES];
            if (!_mouseInside) {
                _trackSelected = NO;
            }
        }
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    self.mouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
    _trackSelected = NO;
}

- (BOOL)isFlipped {
    return NO;
}

- (BOOL)allowsVibrancy {
    return YES;
}

//- (BOOL)wantsLayer {
//    return YES;
//}

// TODO what is it
- (void)setSelected:(BOOL)selected {
    // Do nothing
}

- (void)setTrackSelected:(BOOL)is {
    if (_trackSelected != is) {
        _everSelected = YES;
        _trackSelected = is;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [super drawBackgroundInRect:dirtyRect];
//    return;
    NSImage *img = VKPCGetImagesDictionary()[_trackSelected && _everSelected && _mouseInside ? VKPCImageCellPressedBg : VKPCImageCellBg];
//    NSImage *img = VKPCGetImagesDictionary()[VKPCImageCellBg];
    [img drawInRect:dirtyRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
//    NSLog(@"rowview draw");
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [super drawSelectionInRect:dirtyRect];
}

- (NSBackgroundStyle)interiorBackgroundStyle {
    return NSBackgroundStyleLight;
}

@end
