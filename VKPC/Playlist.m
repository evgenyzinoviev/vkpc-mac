//
//  Playlist.m
//  VKPC
//
//  Created by Evgeny on 12/4/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "Playlist.h"

@implementation Playlist 

- (id)init {
    if (self = [super init]) {
        _tracks = [[NSMutableArray alloc] init];
        _title = [[NSString alloc] init];
        _playlistID = 0;
        _lastPlaylistID = 0;
        _lastTitle = @"";
        _lastTracksCount = 0;
        
        _lastPlaying.index = -1;
        _lastPlaying.status = PlayingStatusNotPlaying;
        
        _playing.index = -1;
        _playing.status = PlayingStatusNotPlaying;
        
        _browser = @"";
        _delegate = nil;
    }
    
    return self;
}

- (void)setTracks:(NSArray *)tracks {
    _lastTracksCount = tracks.count;
    
    [_tracks removeAllObjects];
    [_tracks addObjectsFromArray:tracks];
}

- (void)setPlaylistID:(NSInteger)playlistID {
    _lastPlaylistID = playlistID;
    _playlistID = playlistID;
    
    if (_delegate != nil) {
        [_delegate playlistIDChanged:playlistID];
    }
}

- (void)setTitle:(NSString *)title {
    _lastTitle = [NSString stringWithString:_title];
    _title = [NSString stringWithString:title];
}

// TODO fix in receiver
//- (NSString *)title {
//    return [_title isEqualToString:@""] ? [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleDisplayName] : _title;
//}

//- (NSString *)lastTitle {
//    return [_lastTitle isEqualToString:@""] ? [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleDisplayName] : _lastTitle;
//}

//- (int)lastTracksCount {
//    return lastTracksCount;
//}

//- (int)playlistId {
//    return playlistId;
//}

//- (int)lastPlaylistId {
//    return lastPlaylistId;
//}

//- (PlayingTrackStatus)playing {
//    return playing;
//}

//- (PlayingTrackStatus)lastPlaying {
//    return lastPlaying;
//}

- (void)setPlayingIndex:(NSInteger)index {
    _lastPlaying.index = _playing.index;
    _playing.index = index;
}

- (void)setPlayingStatus:(PlayingStatus)status {
    _lastPlaying.status = _playing.status;
    _playing.status = status;
}

- (void)replaceWithDataFromPlaylist:(Playlist *)pl {
    self.tracks = pl.tracks;
    self.title = pl.title;
    self.playlistID = pl.playlistID;
    self.browser = pl.browser;
    
    [self setPlayingIndex:pl.playing.index];
    [self setPlayingStatus:pl.playing.status];
}

// TODO можно хранить таблицу _id => index, обновлять ее при каждом обновлении tracks
- (int)trackIndexById:(NSString *)_id {
    for (int i = 0; i < _tracks.count; i++) {
        if ([(NSString *)((NSDictionary *)_tracks[i])[@"id"] isEqualToString:_id]) return i;
    }
    return -1;
}

- (void)clear {
    self.title = @"";
    self.browser = @"";
//    [self setTitle:@""];
//    [self setBrowser:@""];
    
    _lastTracksCount = _tracks.count;
    [_tracks removeAllObjects];
    
    self.playlistID = 0;
//    [self setId:0];
    _playing.status = PlayingStatusNotPlaying;
    _playing.index = -1;
    
    _lastPlaying.status = PlayingStatusNotPlaying;
    _lastPlaying.index = -1;
}

- (BOOL)changed {
    return _tracks.count != 0 || _lastTracksCount != _tracks.count || !([_title isEqualToString:_lastTitle]) || _playlistID != _lastPlaylistID;
}

- (BOOL)empty {
    return _tracks.count == 0 && _playlistID <= 0;
}

@end
