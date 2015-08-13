//
//  PlaylistTableRowView.h
//  VKPC
//
//  Created by Eugene on 12/2/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlaylistTableRowView : NSTableRowView

@property (assign, nonatomic) BOOL mouseInside;

- (void)setTrackSelected:(BOOL)is;

@end
