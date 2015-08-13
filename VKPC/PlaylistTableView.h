//
//  PlaylistTableView.h
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlaylistTableController;

@interface PlaylistTableView : NSTableView

@property (strong) PlaylistTableController *controller;

- (int)getContentSize;

@end
