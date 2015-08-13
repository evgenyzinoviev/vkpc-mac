//
//  PlaylistTableController.h
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QueueControllerProtocol.h"
#import "Types.h"

@class PlaylistTableView, Queue, Playlist, PlaylistTableCellView;

@interface PlaylistTableController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, QueueControllerProtocol>

@property (assign) BOOL inited;
@property (strong) Playlist *playlist;

- (void)selectedRowAtIndex:(NSInteger)index;
- (void)setPlaylistDataWithTracks:(NSArray *)tracks title:(NSString *)title id:(NSInteger)_id activeId:(NSString *)activeId activePlaying:(BOOL)activePlaying browser:(NSString *)browser;
+ (void)preSetPlaylistDataWithTracks:(NSArray *)tracks title:(NSString *)title id:(NSInteger)_id activeId:(NSString *)activeId activePlaying:(BOOL)activePlaying browser:(NSString *)browser;
- (void)clearPlaylist;
- (void)showNotification:(NSInteger)trackIndex;
- (void)onQueueTask:(NSInteger)task forQueue:(Queue *)queue;
- (void)playlistUpdated;
- (void)setPlayingRow:(NSInteger)index withStatus:(PlayingStatus)status;
- (void)setPlayingTrackById:(NSString *)_id withStatus:(PlayingStatus)status forPlaylist:(NSInteger)playlistId;
- (int)numberOfRowsInTable;
- (PlaylistTableCellView *)getCellViewForIndex:(NSInteger)index;

@end
