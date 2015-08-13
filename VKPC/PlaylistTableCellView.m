//
//  PlaylistTableCellView.m
//  VKPC
//
//  Created by Eugene on 12/2/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//
// TODO maybe remove lastDrawed

#import "PlaylistTableCellView.h"
#import "VibrantTextField.h"

static const int kTextFieldNormalX = 17;
static const int kTextFieldPlayingX = 46;
static const int kTitleNormalWidth = 315;
static const int kArtistNormalWidth = 283;
static const int kTitlePlayingWidth = 285;
static const int kArtistPlayingWidth = 253;

@implementation PlaylistTableCellView {
    PlayingStatus lastDrawed;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _playingStatus = PlayingStatusNotPlaying;
        lastDrawed = PlayingStatusUndefined;
        [self updateStyle];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _playingStatus = PlayingStatusNotPlaying;
        lastDrawed = PlayingStatusUndefined;
        [self updateStyle];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self drawMode];
}

- (void)setPlayingStatus:(PlayingStatus)playingStatus {
//    NSLog(@"view setplayingstatus");
    lastDrawed = PlayingStatusUndefined;
    _playingStatus = playingStatus;
    [self drawMode];
}

- (NSImageView *)playIconImageView {
    return [self viewWithTag:0];
}

- (NSTextField *)artistTextField {
    return [self viewWithTag:1];
}

- (VibrantTextField *)titleTextField {
    return [self viewWithTag:2];
}

- (VibrantTextField *)durationTextField {
    return [self viewWithTag:3];
}

- (void)setPlay {
    [self.playIconImageView setImage:VKPCGetImagesDictionary()[[[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesInvertPlaylistIcons] == YES ? VKPCImagePause : VKPCImagePlay]];
    [self moveTextFields];
}

- (void)setPause {
    [self.playIconImageView setImage:VKPCGetImagesDictionary()[[[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesInvertPlaylistIcons] == YES ? VKPCImagePlay : VKPCImagePause]];
    [self moveTextFields];
}

- (void)unsetPlay {
    [self.playIconImageView setImage:VKPCGetImagesDictionary()[VKPCImageEmpty]];
    [self moveTextFields];
}

- (void)moveTextFields {
//    NSLog(@"[cellview movetextfields]");
    int x, artistWidth, titleWidth;
    if (_playingStatus <= PlayingStatusNotPlaying) {
        x = kTextFieldNormalX;
        artistWidth = kArtistNormalWidth;
        titleWidth = kTitleNormalWidth;
    } else {
        x = kTextFieldPlayingX;
        artistWidth = kArtistPlayingWidth;
        titleWidth = kTitlePlayingWidth;
    }
    
    NSTextField *artist = [self artistTextField];
    NSTextField *title = [self titleTextField];
    
    NSRect artistRect = artist.frame;
    NSRect titleRect = title.frame;
    
    NSRect newArtistRect = NSMakeRect(x, artistRect.origin.y, artistWidth, artistRect.size.height);
    NSRect newTitleRect = NSMakeRect(x, titleRect.origin.y, titleWidth, titleRect.size.height);
    
    [artist setFrame:newArtistRect];
    [title setFrame:newTitleRect];
    
    [self setNeedsDisplay:YES];
}

- (void)updateStyle {
    switch (GetInterfaceStyle()) {
        case InterfaceStyleLegacy:
            [self.titleTextField setTextColor:[NSColor colorWithSRGBRed:0.529 green:0.537 blue:0.549 alpha:1]];
            [self.durationTextField setTextColor:[NSColor colorWithSRGBRed:0.71 green:0.714 blue:0.718 alpha:1]];
            break;
            
        case InterfaceStyleYosemite:
            [self.titleTextField setTextColor:[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.35]];
            [self.durationTextField setTextColor:[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.17]];
            break;
            
        case InterfaceStyleYosemiteDark:
            [self.titleTextField setTextColor:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.28]];
            [self.durationTextField setTextColor:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.15]];
            break;
    }
}

- (void)drawMode {
//    if (lastDrawed != _playingStatus) {
        switch (_playingStatus) {
            case PlayingStatusNotPlaying:
                [self unsetPlay];
                break;
                
            case PlayingStatusPaused:
                [self setPause];
                break;
                
            case PlayingStatusPlaying:
                [self setPlay];
                break;
            
            default:
                break;
        }
//    }
    
    lastDrawed = _playingStatus;
}

@end
