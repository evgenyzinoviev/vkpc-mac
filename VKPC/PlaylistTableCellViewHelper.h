//
//  PlaylistTableCellViewHelper.h
//  VKPC
//
//  Created by Evgeny on 12/4/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlaylistTableCellViewHelper : NSObject

+ (NSTableCellView *)initialDrawingForView:(NSTableCellView *)view;
+ (NSImageView *)playIconImageViewForView:(NSTableCellView *)view;
+ (NSTextField *)artistTextFieldForView:(NSTableCellView *)view;
+ (NSTextField *)titleTextFieldForView:(NSTableCellView *)view;
+ (NSTextField *)durationTextFieldForView:(NSTableCellView *)view;
+ (void)setPlayForView:(NSTableCellView *)view;
+ (void)setPauseForView:(NSTableCellView *)view;
+ (void)unsetPlayForView:(NSTableCellView *)view;
+ (void)moveTextFieldsForView:(NSTableCellView *)view;

@end
