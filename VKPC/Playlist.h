//
//  Playlist.h
//  VKPC
//
//  Created by Evgeny on 12/4/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PlaylistDelegate <NSObject>
- (void)playlistIDChanged:(NSInteger)playlistID;
+ (void)playlistIDChanged:(NSInteger)playlistID;
@end

@interface Playlist : NSObject

@property (strong, nonatomic) NSMutableArray *tracks;

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *lastTitle;

@property (assign, nonatomic) NSInteger playlistID;
@property (assign) NSInteger lastPlaylistID;

@property (assign) NSInteger lastTracksCount;

@property (assign) PlayingTrackStatus playing;
@property (assign) PlayingTrackStatus lastPlaying;

@property (strong) NSString *browser; // TODO delete
@property (strong) id<PlaylistDelegate> delegate;

- (void)replaceWithDataFromPlaylist:(Playlist *)pl;
- (int)trackIndexById:(NSString *)_id;
- (void)setPlayingStatus:(PlayingStatus)status;
- (void)setPlayingIndex:(NSInteger)index;
- (void)clear;
- (BOOL)changed;
- (BOOL)empty;

@end
