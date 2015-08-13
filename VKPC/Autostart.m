//
//  Autostart.m
//  VKPC
//
//  Created by Eugene on 11/9/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//
// Based on https://stackoverflow.com/questions/608963/register-as-login-item-with-cocoa

#import "Autostart.h"

@implementation Autostart

static LSSharedFileListItemRef itemRefInLoginItems() {
    LSSharedFileListItemRef res = nil;
    
    // Get the app's URL.
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    // Iterate over the LoginItems.
    NSArray *loginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            // Again, use toll-free bridging.
            NSURL *itemURL = (__bridge NSURL *)itemURLRef;
            if ([itemURL isEqual:bundleURL]) {
                res = itemRef;
                break;
            }
        }
    }
    // Retain the LoginItem reference.
    if (res != nil) CFRetain(res);
    CFRelease(loginItemsRef);
    CFRelease((__bridge CFTypeRef)(loginItems));
    
    return res;
}

+ (BOOL)isLaunchAtStartup {
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = itemRefInLoginItems();
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    // Release the reference if it exists.
    if (itemRef != nil) {
        CFRelease(itemRef);
    }
    
    return isInList;
}

+ (void)toggleLaunchAtStartup {
    // Toggle the state.
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    } else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = itemRefInLoginItems();
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

@end
