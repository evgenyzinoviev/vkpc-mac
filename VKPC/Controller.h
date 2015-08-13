//
//  Controller.h
//  VKPC
//
//  Created by Eugene on 10/23/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Playlist.h"

@interface Controller : NSObject <PlaylistDelegate>

+ (void)prev;
+ (void)next;
+ (void)playpause;
+ (void)operateTrack:(NSString *)trackID;
+ (NSString *)findRunningAppAndPrepareASForCommand:(NSString *)command;
+ (void)sendCommand:(NSString *)command;
+ (void)handleClient:(NSDictionary *)json;

+ (BOOL)isASBrowser:(NSInteger)browser;
+ (NSString *)JSONForCommand:(NSString *)command data:(NSObject *)data;


#ifdef DEBUG
+ (void)debugInject;
+ (void)debugSendPlay;
+ (void)debugCopyJS;
+ (void)debugCopyAS;
#endif

@end
