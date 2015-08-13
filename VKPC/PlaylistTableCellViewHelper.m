//
//  PlaylistTableCellViewHelper.m
//  VKPC
//
//  Created by Evgeny on 12/4/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import "PlaylistTableCellViewHelper.h"

@implementation PlaylistTableCellViewHelper

+ (NSTableCellView *)initialDrawingForView:(NSTableCellView *)view {
    [[self titleTextFieldForView:view] setTextColor:[NSColor colorWithSRGBRed:0.529 green:0.537 blue:0.549 alpha:1]];
    [[self durationTextFieldForView:view] setTextColor:[NSColor colorWithSRGBRed:0.71 green:0.714 blue:0.718 alpha:1]];
    return view;
}

+ (NSImageView *)playIconImageViewForView:(NSTableCellView *)view {
    return [[view subviews] objectAtIndex:0];
}

+ (NSTextField *)artistTextFieldForView:(NSTableCellView *)view {
    return [[view subviews] objectAtIndex:1];
}

+ (NSTextField *)titleTextFieldForView:(NSTableCellView *)view {
    return [[view subviews] objectAtIndex:2];
}

+ (NSTextField *)durationTextFieldForView:(NSTableCellView *)view {
    return [[view subviews] objectAtIndex:3];
}

+ (void)setPlayForView:(NSTableCellView *)view {
    NSImageView *image = [self playIconImageViewForView:view];
    [image setImage:[NSImage imageNamed:@"pl_play"]];
    //self.playingStatus = PlayingStatusPlaying;
    
    [self moveTextFieldsForView:view];
}

+ (void)setPauseForView:(NSTableCellView *)view {
    NSImageView *image = [self playIconImageViewForView:view];
    [image setImage:[NSImage imageNamed:@"pl_pause"]];
    //self.playingStatus = PlayingStatusPaused;
    
    [self moveTextFieldsForView:view];
}

+ (void)unsetPlayForView:(NSTableCellView *)view {
    NSImageView *image = [self playIconImageViewForView:view];
    [image setImage:[NSImage imageNamed:@"empty"]];
    //self.playingStatus = PlayingStatusNotPlaying;
    
    [self moveTextFieldsForView:view];
}

+ (void)moveTextFieldsForView:(NSTableCellView *)view {
    int x = 20;
    //int x = playingStatus == PlayingStatusNotPlaying ? kTextFieldNormalX : kTextFieldPlayingX;
    
    NSTextField *artist = [self artistTextFieldForView:view];
    NSTextField *title = [self titleTextFieldForView:view];
    
    NSRect artistRect = artist.frame;
    NSRect titleRect = title.frame;
    
    NSRect newArtistRect = NSMakeRect(x, artistRect.origin.y, artistRect.size.width, artistRect.size.height);
    NSRect newTitleRect = NSMakeRect(x, titleRect.origin.y, titleRect.size.width, titleRect.size.height);
    
    [artist setFrame:newArtistRect];
    [title setFrame:newTitleRect];
    
    // Fucking shit
    // TODO ?
    // [view setNeedsDisplay:YES];
}

@end
