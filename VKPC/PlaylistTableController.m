//
//  PlaylistTableController.m
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "PopoverController.h"
#import "PlaylistTableController.h"
#import "PlaylistTableCellView.h"
#import "PlaylistTableView.h"
#import "Queue.h"
#import "QueueControllerProtocol.h"
#import "Playlist.h"
#import "Controller.h"
#import "Playlist.h"

static NSString * const kTitleKey = @"title";
static NSString * const kArtistKey = @"artist";
static NSString * const kPlayImageKey = @"playImage";
static NSString * const kDurationKey = @"duration";
static NSString * const kIdKey = @"id";

static Playlist *prePlaylist = nil;
//static const int kRowHeight = 51;

@implementation PlaylistTableController {
    BOOL haveTrackForNextPlaylist;
    PlaylistTableView *playlistTableView;
    NSArrayController *playlistArrayController;
    NSView *placeholderView;
    Queue *setTracksQueue;
    NSMutableDictionary *trackForNextPlaylist;
}

- (id)init {
    if (self = [super init]) {
        _inited = NO;
        haveTrackForNextPlaylist = NO;
        
        trackForNextPlaylist = [[NSMutableDictionary alloc] init];
        
        setTracksQueue = [[Queue alloc] init];
        [setTracksQueue setHandler:self];
        
        _playlist = [[Playlist alloc] init];
        
        playlistTableView = [PopoverController shared].playlistTableView;
        playlistArrayController = [PopoverController shared].playlistArrayController;
        placeholderView = [PopoverController shared].customView;
        //    popoverController = [PopoverController shared];
        
        // set some variables
        //    playlistTableView = _playlistTableView;
        //    playlistArrayController = controller;
        //    placeholderView = view;
        //    popoverController = _popoverController;
        
        // init some objects ..
        NSScrollView *scrollView = [[PopoverController shared] scrollView];
        [[scrollView contentView] setPostsBoundsChangedNotifications: YES];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(viewDidScroll:) name:NSViewBoundsDidChangeNotification object:nil];
        
        playlistTableView.controller = self;
        //    [playlistTableView setController:self];
        [playlistTableView setDataSource:self];
        [playlistTableView setDelegate:self];
        [playlistTableView numberOfRows];
        
        [playlistArrayController addObject:[_playlist tracks]];
        
        if (prePlaylist != nil) {
            [setTracksQueue addTask:prePlaylist];
        } else {
            [self playlistUpdated];
        }
        _inited = YES;

    }
    return self;
}


//- (void)initController:(PlaylistTableView *)_playlistTableView withArrayController:(NSArrayController *)controller placeholderView:(NSView *)view withPopoverController:(PopoverController *)_popoverController {
//    }

//- (BOOL)inited {
//    return inited;
//}

//- (void)dealloc {
//    [super dealloc];
//}

/** Playlist related methods **/

//- (Playlist *)playlist {
//    return playlist;
//}

- (void)setPlaylistDataWithTracks:(NSArray *)tracks title:(NSString *)title id:(NSInteger)_id activeId:(NSString *)activeId activePlaying:(BOOL)activePlaying browser:(NSString *)browser {
    for (int i = 0; i < [tracks count]; i++) {
        [[tracks objectAtIndex:i] setObject:VKPCGetImagesDictionary()[VKPCImageEmpty] forKey:kPlayImageKey];
    }
    Playlist *pl = [[Playlist alloc] init];
    pl.title = title;
    pl.tracks = [NSMutableArray arrayWithArray:tracks];
    pl.playlistID = _id;
    pl.browser = browser;
    
    if (![activeId isEqualToString:@""]) {
        [pl setPlayingIndex:[pl trackIndexById:activeId]];
        [pl setPlayingStatus:(activePlaying ? PlayingStatusPlaying : PlayingStatusPaused)];
    } else {
        [pl setPlayingIndex:-1];
        [pl setPlayingStatus:PlayingStatusNotPlaying];
    }
    
    [setTracksQueue addTask:pl];
}

+ (void)preSetPlaylistDataWithTracks:(NSArray *)tracks title:(NSString *)title id:(NSInteger)_id activeId:(NSString *)activeId activePlaying:(BOOL)activePlaying browser:(NSString *)browser {
    if (prePlaylist == nil) {
        prePlaylist = [[Playlist alloc] init];
    }
    prePlaylist.tracks = [NSMutableArray arrayWithArray:tracks];
    prePlaylist.title = title;
    prePlaylist.browser = browser;
    prePlaylist.playlistID = _id;
    
    if (![activeId isEqualToString:@""]) {
        int index = [prePlaylist trackIndexById:activeId];
        if (index != [prePlaylist playing].index) [self showNotification:index];
        [prePlaylist setPlayingIndex:index];
        [prePlaylist setPlayingStatus:(activePlaying ? PlayingStatusPlaying : PlayingStatusPaused)];
    }  else {
        [prePlaylist setPlayingIndex:-1];
        [prePlaylist setPlayingStatus:PlayingStatusNotPlaying];
    }
}

- (void)clearPlaylist {
    if (![_playlist empty]) {
        NSLog(@"clearPlaylist(): is not empty");
        if (_inited) {
            Playlist *pl = [[Playlist alloc] init];
            [pl clear];
            
            [setTracksQueue addTask:pl];
        } else {
            [_playlist clear];
        }
    }
}

- (void)onQueueTask:(id)task forQueue:(Queue *)queue {
    if (setTracksQueue == queue) {
        [_playlist replaceWithDataFromPlaylist:task];
        
        if (haveTrackForNextPlaylist) {
            NSInteger toPlaylistId = [(NSNumber *)[trackForNextPlaylist objectForKey:@"playlistId"] intValue];
            if (toPlaylistId == _playlist.playlistID) {
                [_playlist setPlayingIndex:[_playlist trackIndexById:[trackForNextPlaylist objectForKey:@"id"]]];
                [_playlist setPlayingStatus:( [(NSString *)[trackForNextPlaylist objectForKey:@"status"] isEqualToString:@"play"] ? PlayingStatusPlaying : PlayingStatusPaused )];
            }
            [trackForNextPlaylist removeAllObjects];
            haveTrackForNextPlaylist = false;
        }
        
        [self playlistUpdated];
    }
}

- (void)playlistUpdated {
    if ([_playlist lastPlaying].index != -1 && [_playlist lastPlaying].index < [self numberOfRowsInTable]) {
        [[self getCellViewForIndex:_playlist.lastPlaying.index] setPlayingStatus:PlayingStatusNotPlaying];
    }
    
    // Update title
    [[PopoverController shared] updateTitle:_playlist.title];
    
    // Update tracks
    [playlistTableView beginUpdates];
    [playlistTableView performSelectorOnMainThread:@selector(reloadData)
                                        withObject:nil
                                     waitUntilDone:YES];
    
    NSLog(@"in playlistUpdated: dispatch_async() now");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"<reloadData done>");
        [playlistTableView endUpdates];
        [placeholderView setHidden:(_playlist.tracks.count > 0)]; // TODO maybe just send message to popoverController?
        
        if ([_playlist playing].index != -1) {
            [self setPlayingRow:_playlist.playing.index withStatus:[_playlist playing].status];
        } else if ([_playlist lastPlaying].index != -1) {
            [self unselectRow:_playlist.lastPlaying.index];
        }
        
        [[PopoverController shared] resizeWithContentHeight:[playlistTableView getContentSize]];
        [setTracksQueue taskDone];
    });
}

- (void)setPlayingTrackById:(NSString *)_id withStatus:(PlayingStatus)status forPlaylist:(NSInteger)playlistId {
    if (playlistId != _playlist.playlistID) {
        [trackForNextPlaylist setValue:_id forKey:@"id"];
        [trackForNextPlaylist setValue:(status == PlayingStatusPlaying ? @"play" : @"pause") forKey:@"status"];
        [trackForNextPlaylist setValue:[NSNumber numberWithLong:playlistId] forKey:@"playlistId"];
        haveTrackForNextPlaylist = YES;
        return;
    }
    
    int index = [_playlist trackIndexById:_id];
    if (index != -1) {
        if ([_playlist playing].index != index) [self showNotification:index];
        
        if (_inited) {
            if (index <= [playlistTableView numberOfRows]) {
                //if ([playlist playing].index != index) [self showNotification:index];
                [self setPlayingRow:index withStatus:status];
            }
        } else {
            [_playlist setPlayingIndex:index];
            [_playlist setPlayingStatus:status];
        }
    }
}

+ (void)showNotification:(NSInteger)trackIndex {
    if (trackIndex < prePlaylist.tracks.count && [[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesShowNotifications] == YES) {
        NSDictionary *track = [[prePlaylist tracks] objectAtIndex:trackIndex];
        ShowNotification([track objectForKey:@"artist"], [track objectForKey:@"title"]);
    }
}

- (void)showNotification:(NSInteger)trackIndex {
    if (trackIndex < _playlist.tracks.count && [[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesShowNotifications] == YES) {
        NSDictionary *track = [[_playlist tracks] objectAtIndex:trackIndex];
        ShowNotification([track objectForKey:@"artist"], [track objectForKey:@"title"]);
    }
}

/** UI **/

- (void)viewDidScroll:(NSNotification *)notification {
    NSScrollView *view = [[PopoverController shared] scrollView];
    
    // Fix for retina
    if ([view contentView].bounds.origin.y != (int)[view contentView].bounds.origin.y) {
        NSPoint point = NSMakePoint([view contentView].bounds.origin.x, (int)([view contentView].bounds.origin.y + 0.5));
        [[view documentView] scrollPoint:point];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _playlist.tracks.count;
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row {
    if (row < [[_playlist tracks] count])
        return [[_playlist tracks] objectAtIndex:row];
    return nil;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    PlaylistTableCellView *view = [playlistTableView makeViewWithIdentifier:@"VKPCCell" owner:self];
    if (view == nil) {
        NSLog(@"VIEW IS NIL");
    }
    PlayingStatus newPlayingStatus = _playlist.playing.index == row ? _playlist.playing.status : PlayingStatusNotPlaying;
        [view setPlayingStatus:newPlayingStatus];
    return view;
}

// User clicked on row
- (void)selectedRowAtIndex:(NSInteger)index {
    NSDictionary *track = _playlist.tracks[index];
    
    if (_playlist.playing.index != index) {
        [self setPlayingRow:index withStatus:PlayingStatusPlaying];
        
        [_playlist setPlayingIndex:index];
        [_playlist setPlayingStatus:PlayingStatusPlaying];
    } else if (_playlist.playing.index == index) {
        if (_playlist.playing.status == PlayingStatusPlaying) {
            [self setPlayingRow:index withStatus:PlayingStatusPaused];
            [_playlist setPlayingStatus:PlayingStatusPaused];
        } else {
            [self setPlayingRow:index withStatus:PlayingStatusPlaying];
            [_playlist setPlayingStatus:PlayingStatusPlaying];
        }
    }
    
    // TODO call script
//    [Script executeForAll:@"common" withCommand:@"operateTrack" withData:[track objectForKey:kIdKey]];
    [Controller operateTrack:track[kIdKey]];
}

- (void)setPlayingRow:(NSInteger)index withStatus:(PlayingStatus)status {
    if (index >= [self numberOfRowsInTable]) {
        return;
    }
    
    PlaylistTableCellView *cellView = [self getCellViewForIndex:index];
    
    if (_playlist.lastPlaying.index != index) {
        if (_playlist.lastPlaying.index >= 0 && _playlist.lastPlaying.index < [self numberOfRowsInTable]) {
            [[self getCellViewForIndex:_playlist.lastPlaying.index] setPlayingStatus:PlayingStatusNotPlaying];
        }
    }
    
    if (_playlist.playing.index != index) {
        if (_playlist.playing.index != -1 && _playlist.playing.index < [self numberOfRowsInTable]) {
            [[self getCellViewForIndex:_playlist.playing.index] setPlayingStatus:PlayingStatusNotPlaying];
        }
        [_playlist setPlayingIndex:index];
        [_playlist setPlayingStatus:status];
        
        [cellView setPlayingStatus:status];
    } else if (_playlist.playing.index == index) {
        [_playlist setPlayingStatus:status];
        [cellView setPlayingStatus:status];
    }
    
    [playlistTableView scrollRowToVisible:index];
}

- (void)unselectRow:(NSInteger)index {
    if (index >= [self numberOfRowsInTable]) {
        return;
    }
    
    PlaylistTableCellView *cellView = [self getCellViewForIndex:index];
    [cellView setPlayingStatus:PlayingStatusNotPlaying];
}

- (PlaylistTableCellView *)getCellViewForIndex:(NSInteger)index {
    return [playlistTableView viewAtColumn:0 row:index makeIfNecessary:YES];
}

- (int)numberOfRowsInTable {
    return (int)[playlistTableView numberOfRows];
}

@end
