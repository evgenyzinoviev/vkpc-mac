//
//  PlaylistTableCellView.h
//  VKPC
//
//  Created by Eugene on 12/2/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlaylistTableCellView : NSTableCellView

@property (assign, nonatomic) PlayingStatus playingStatus;

//- (void)setPlay;
//- (void)setPause;
//- (void)unsetPlay;
//- (void)moveTextFields;
- (void)updateStyle;
- (void)drawMode;
//- (NSImageView *)playIconImageView;
//- (NSTextField *)artistTextField;
//- (NSTextField *)titleTextField;
//- (NSTextField *)durationTextField;
//- (void)setMode:(PlayingStatus)mode;

@end
