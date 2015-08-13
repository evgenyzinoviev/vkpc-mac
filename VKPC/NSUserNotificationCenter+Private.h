//
//  NSUserNotificationCenter+Private.h
//  VKPC
//
//  Created by Eugene on 11/18/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserNotificationCenter (Private)

//- (void)_removeAllDisplayedNotifications;
- (void)_removeDisplayedNotification:(NSUserNotification *)notification;

@end

