//
//  HostsHack.h
//  VKPC
//
//  Created by Eugene on 10/30/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const VKPCHostsHackTaskFinished;

@interface HostsHack : NSObject

+ (void)check;
+ (void)hack;
+ (BOOL)found;
+ (void)showWindow;
+ (int)doHack;

@end
