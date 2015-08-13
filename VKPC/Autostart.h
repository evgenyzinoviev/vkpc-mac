//
//  Autostart.h
//  VKPC
//
//  Created by Eugene on 11/9/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Autostart : NSObject

+ (BOOL)isLaunchAtStartup;
+ (void)toggleLaunchAtStartup;

@end
