//
//  Types.h
//  VKPC
//
//  Created by Eugene on 10/22/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#ifndef VKPC_Types_h
#define VKPC_Types_h

typedef enum {
    PlayingStatusUndefined = -1,
    PlayingStatusNotPlaying = 0,
    PlayingStatusPlaying = 1,
    PlayingStatusPaused = 2
} PlayingStatus;

typedef struct {
    NSInteger index;
    PlayingStatus status;
} PlayingTrackStatus;

typedef enum {
    InterfaceStyleLegacy,
    InterfaceStyleYosemite,
    InterfaceStyleYosemiteDark
} InterfaceStyle;

typedef enum {
    PopoverStateSystemConfigurationRequired,
    PopoverStatePlaylistNotLoaded,
    PopoverStatePlaylistLoaded
} PopoverState;

enum {
    BrowserChrome = 0,
    BrowserFirefox = 1,
    BrowserSafari = 2,
    BrowserOpera = 3,
    BrowserYandex = 4,
    
    BrowsersCount = 5
};

#endif
