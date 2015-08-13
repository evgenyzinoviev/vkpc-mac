//
//  global.m
//  VKPC
//
//  Created by Eugene on 11/28/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "Global.h"
#import <CoreServices/CoreServices.h>
#import "NSTimer+Blocks.h"
#import "NSUserNotificationCenter+Private.h"

#include <stdlib.h>
#include <math.h>

int const VKPCWSServerPort = 56130;
char * const VKPCWSServerHost = "127.0.0.1";
char * const VKPCWSClientHost = "vkpc-local.ch1p.com";
//char * const VKPCHostsFile = "/private/etc/hosts";

NSString * const VKPCAppHomeURL = @"https://ch1p.com/vkpc/?v={version}";
NSString * const CH1PEmail = @"ch1p@ch1p.com";

#ifdef DEBUG
BOOL const VKPCIsDebug = YES;
#else 
BOOL const VKPCIsDebug = NO;
#endif 

BOOL const VKPCIsServerLogsEnabled = NO;
BOOL VKPCIsYosemite = NO;

NSString * const VKPCEZCopyright = @"Eugene Z";
NSString * const VKPCEZCopyrightYears = @" © 2013-2015";
NSString * const VKPCEZURL = @"https://vk.com/ez";

NSString * const VKPCPreferencesShowNotifications = @"VKPCShowNotifications";
NSString * const VKPCPreferencesInvertPlaylistIcons = @"VKPCInvertPlaylistIcons";
NSString * const VKPCPreferencesCatchMediaButtons = @"VKPCCatchMediaButtons";
NSString * const VKPCPreferencesBrowser = @"VKPCBrowser";
NSString * const VKPCPreferencesStatisticReportedTimestamp = @"VKPCStatisticReportedTimestamp";
NSString * const VKPCPreferencesUUID = @"VKPCUUID";
NSString * const VKPCPreferencesUseExtensionMode = @"VKPCUseExtensionMode";

NSString * const kAppleInterfaceStyle = @"AppleInterfaceStyle";
NSString * const kAppleInterfaceThemeChangedNotification = @"AppleInterfaceThemeChangedNotification";
NSString * const kAppleInterfaceStyleDark = @"Dark";
NSString * const kCFBundleDisplayName = @"CFBundleDisplayName";
NSString * const kCFBundleShortVersionString = @"CFBundleShortVersionString";
NSString * const kCFBundleVersion = @"CFBundleVersion";

int VKPCSessionID;
pid_t VKPCPID;

void VKPCInitGlobals() {
    SInt32 major, minor;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);

    VKPCIsYosemite = major >= 10 && minor >= 10;
    VKPCSessionID = arc4random() % 65536;
    VKPCPID = [[NSProcessInfo processInfo] processIdentifier];
}

void VKPCInitUUID() {
    NSString *currentUUID = [[NSUserDefaults standardUserDefaults] stringForKey:VKPCPreferencesUUID];
    if ([currentUUID isEqualToString:@""]) {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
        
        [[NSUserDefaults standardUserDefaults] setObject:uuidString forKey:VKPCPreferencesUUID];
    }
}

static NSUserNotification *lastNotification;
static BOOL isLowerThan10_9() {
    SInt32 major, minor;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    
    return major == 10 && minor < 9;
}
static void removeNotification(NSUserNotification *notification) {
//    if (isLowerThan10_9()) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] _removeDisplayedNotification:notification];
//    } else {
//        [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
//    }
}
void ShowNotification(NSString *title, NSString *text) {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:title];
    [notification setInformativeText:text];
    [notification setHasActionButton:NO];
    
    if (lastNotification != nil) {
        removeNotification(lastNotification);
    }
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    [NSTimer scheduledTimerWithTimeInterval:4.0 block:^{
        removeNotification(notification);
    } repeats:NO];
    
    lastNotification = notification;
}

NSString * GetFileFromResourceAsString(NSString *fileName, NSError * __autoreleasing * error) {
    NSString *path = [[fileName lastPathComponent] stringByDeletingPathExtension];
    NSString *type = [fileName pathExtension];
    NSError *localError = nil;
    
    NSString *resPath = [[NSBundle mainBundle] pathForResource:path ofType:type];
    NSURL *url = [NSURL fileURLWithPath:resPath];
    NSString *content = nil;
    content = [[NSString alloc]
               initWithContentsOfURL:url
               encoding:NSUTF8StringEncoding
               error:&localError];
    
    if (localError || content == nil) {
        *error = localError;
        NSLog(@"Error reading file %@\n%@", url, [localError localizedFailureReason]);
    }
    
    return content;
}

NSString * GetSystemFontName() {
    return VKPCIsYosemite ? @"Helvetica Neue" : @"Lucida Grande";
}

InterfaceStyle GetInterfaceStyle() {
    if (VKPCIsYosemite) {
        NSString *theme = [[NSUserDefaults standardUserDefaults] stringForKey:kAppleInterfaceStyle];
        if (theme != nil && [theme isKindOfClass:[NSString class]] && [theme isEqualToString:kAppleInterfaceStyleDark]) {
            return InterfaceStyleYosemiteDark;
        }
        return InterfaceStyleYosemite;
    }
    return InterfaceStyleLegacy;
}

long GetTimestamp() {
    return (long)floor([[NSDate date] timeIntervalSince1970]);
}

BOOL IsAnotherProcessRunning() {
    NSArray *list = [[NSWorkspace sharedWorkspace] runningApplications];
    for (int i = 0; i < list.count; i++) {
        NSRunningApplication *app = list[i];
        if ([[app bundleIdentifier] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]
            && [app processIdentifier] != VKPCPID) {
            return YES;
        }
    }
    return NO;
}

void DebugLog(const char *str) {
//    printf("><> %s\n", str);
}

//////////////////////////////////// Images ////////////////////////////////////

NSString * const VKPCImageEmpty = @"empty";
NSString * const VKPCImageCellBg = @"pl_cell_bg";
NSString * const VKPCImageCellPressedBg = @"pl_cell_pressed_bg";
NSString * const VKPCImagePause = @"pl_pause";
NSString * const VKPCImagePlay = @"pl_play";
NSString * const VKPCImageTitleSeparator = @"pl_title_separator";
NSString * const VKPCImageSettings = @"settings";
NSString * const VKPCImageSettingsPressed = @"settings_pressed";
NSString * const VKPCImageStatus = @"status";
NSString * const VKPCImageStatusPressed = @"status_pressed";

static NSString * const kImagesBundleLegacy = @"ImagesLegacy";
static NSString * const kImagesBundleYosemite = @"ImagesYosemite";
static NSString * const kImagesBundleYosemiteDark = @"ImagesYosemiteDark";

static BOOL imagesInited = NO;
static NSArray *imageNames;
static NSMutableDictionary *imageBundles; // @{<bundleName>: NSBundle}
static NSMutableDictionary *allImages; // @{<bundleName>: @{<imageName>: NSImage, ...}}

NSDictionary * VKPCGetImagesDictionary() {
    if (!imagesInited) {
        allImages = [[NSMutableDictionary alloc] init];
        imageBundles = [[NSMutableDictionary alloc] init];
        
        imageNames = @[VKPCImageEmpty, VKPCImageCellBg, VKPCImageCellPressedBg,
                       VKPCImagePause, VKPCImagePlay, VKPCImageTitleSeparator, VKPCImageSettings,
                       VKPCImageSettingsPressed, VKPCImageStatus, VKPCImageStatusPressed];
        
        // Loading bundles
        NSArray *bundlePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"bundle" inDirectory:@""];
        for (NSString *bundlePath in bundlePaths) {
            NSString *bundleKey = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
            if ([bundleKey hasPrefix:@"Images"]) {
                imageBundles[bundleKey] = [NSBundle bundleWithPath:bundlePath];
            }
        }
        
        imagesInited = YES;
    }
    
    NSString *bundleKey;
    switch (GetInterfaceStyle()) {
        case InterfaceStyleYosemite:
            bundleKey = kImagesBundleYosemite;
            break;
        case InterfaceStyleLegacy:
            bundleKey = kImagesBundleLegacy;
            break;
        case InterfaceStyleYosemiteDark:
            bundleKey = kImagesBundleYosemiteDark;
            break;
    }
    
    if (allImages[bundleKey] != nil) {
//        NSLog(@"[VKPCGetImagesDictionary] returning from cache, bundleKey = %@", bundleKey);
        return (NSDictionary *)allImages[bundleKey];
    }
    
    allImages[bundleKey] = [[NSMutableDictionary alloc] init];
    for (NSString *named in imageNames) {
        NSImage *img = [(NSBundle *)imageBundles[bundleKey] imageForResource:named];
        allImages[bundleKey][named] = img;
    }
    
    return (NSDictionary *)allImages[bundleKey];
}