//
//  Controller.m
//  VKPC
//
//  Created by Eugene on 10/23/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "Controller.h"
#import "PopoverController.h"
#import "Server.h"

static NSString * const kASExecuteJSChrome = @"execute javascript";
static NSString * const kASExecuteJSSafari = @"do JavaScript";
static NSString * const kASCurrentTabChrome = @"active tab";
static NSString * const kASCurrentTabSafari = @"current tab";
static NSString * const kASTabTitleChrome = @"title of";
static NSString * const kASTabTitleSafari = @"name of";

static NSString * const kCommandAfterInjection = @"afterInjection";
static NSString * const kCommandPlayPause = @"playpause";
static NSString * const kCommandPrev = @"prev";
static NSString * const kCommandNext = @"next";
static NSString * const kCommandOperateTrack = @"operateTrack:{id}";

static NSArray *browsers = nil;
static NSString *scriptJS;
#ifdef DEBUG
static NSString *scriptJSUnescaped;
#endif
static NSString *scriptAS;
static NSMutableDictionary *cache = nil;
static NSTimer *timer = nil;
static NSInteger browser;
static BOOL initialized = NO;

@implementation Controller

+ (void)initialize {
    if (initialized) {
        return;
    }
    
    browsers = @[
                     @[@{@"id": @"com.google.Chrome", @"name": @"Google Chrome", @"key": @"chrome"}, @{@"id": @"com.google.Chrome.canary", @"name": @"Google Chrome Canary", @"key": @"chromecanary"}],
                     @[@{@"id": @"org.mozilla.firefox", @"name": @"Firefox", @"key": @"firefox"}],
                     @[@{@"id": @"com.apple.Safari", @"name": @"Safari", @"key": @"safari"}],
                     @[@{@"id": @"com.operasoftware.Opera", @"name": @"Opera", @"key": @"opera"}, @{@"id": @"com.operasoftware.OperaNext", @"name": @"Opera Next", @"key": @"operanext"}],
                     @[@{@"id": @"ru.yandex.desktop.yandex-browser", @"name": @"Yandex", @"key": @"yandex"}]
                     ];
    NSError *error = nil;
    
    scriptJS = GetFileFromResourceAsString(@"inject.js", &error);
    scriptAS = GetFileFromResourceAsString(@"inject.as", &error);
    
    if (error) {
        NSLog(@"Error while reading from resources: %@", error);
        // TODO something
        return;
    }
    
    scriptJS = [scriptJS stringByReplacingOccurrencesOfString:@"{sid}" withString:[NSString stringWithFormat:@"%d", VKPCSessionID]];
//    scriptJS = [scriptJS stringByReplacingOccurrencesOfString:@"{debug}" withString:(VKPCIsDebug ? @"true" : @"false")];
    
#ifdef DEBUG
    scriptJSUnescaped = [NSString stringWithString:scriptJS];
#endif
    
    scriptJS = [scriptJS stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    scriptJS = [scriptJS stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    cache = [[NSMutableDictionary alloc] init];

//    if (NO)
    [self setupTimer];
    
    browser = [[NSUserDefaults standardUserDefaults] integerForKey:VKPCPreferencesBrowser];
    
    [[NSUserDefaults standardUserDefaults] addObserver:(id)[Controller class]
                                            forKeyPath:VKPCPreferencesBrowser
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    initialized = YES;
}

+ (void)setupTimer {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    
    [self timerCallback:nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:[Controller class]
                                           selector:@selector(timerCallback:)
                                           userInfo:nil
                                            repeats:YES];
}

#ifdef DEBUG
+ (void)debugSendPlay {
    [Controller playpause];
}

+ (void)debugInject {
    [Controller sendCommand:kCommandAfterInjection];
}

+ (void)debugCopyJS {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:scriptJSUnescaped forType:NSStringPboardType];
}

+ (void)debugCopyAS {
    NSString *code = [self findRunningAppAndPrepareASForCommand:kCommandAfterInjection];
    if (code != nil) {
        NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
        [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
        [pasteBoard setString:code forType:NSStringPboardType];
    } else {
        NSLog(@"[Controller debugCopyAS] code == nil");
    }
}
#endif

//static BOOL playlistDelegateSet = NO;
+ (void)timerCallback:(NSTimer *)timer {
    if ([[PopoverController shared] playlistTableController] != nil && [[PopoverController shared] playlistTableController].playlist.delegate == nil) {
        [[PopoverController shared].playlistTableController.playlist setDelegate:(id)[self class]];
        NSLog(@"[Controller timerCallback] playlist delegate set");
//        playlistDelegateSet = YES;
    }
    
    if ([self isASBrowser:browser]) {
        [Controller sendCommand:kCommandAfterInjection];
    } else if ([Server connectedCount:browser] <= 0) {
        [[PopoverController shared].playlistTableController clearPlaylist];
    }
}

+ (void)prev {
    [Controller sendCommand:kCommandPrev];
}

+ (void)next {
    [Controller sendCommand:kCommandNext];
}

+ (void)playpause {
    [Controller sendCommand:kCommandPlayPause];
}

+ (void)operateTrack:(NSString *)trackID {
    [Controller sendCommand:[kCommandOperateTrack stringByReplacingOccurrencesOfString:@"{id}" withString:trackID]];
}

+ (void)sendCommand:(NSString *)command {
    if ([self isASBrowser:browser]) {
        NSString *code = [self findRunningAppAndPrepareASForCommand:command];
        if (code == nil) {
    //        NSLog(@"[Controller sendCommand:] code == nil, returning");
            // Clear playlist?
            [[PopoverController shared].playlistTableController clearPlaylist];
            return;
        }
        
        NSAppleScript *as = [[NSAppleScript alloc] initWithSource:code];
        NSDictionary *error = nil;
        NSAppleEventDescriptor *result = [as executeAndReturnError:&error];
        
        if (error) {
            NSLog(@"[Controller sendCommand:] error: %@", error);
        } else if ([command isEqualToString:kCommandAfterInjection]) {
            int returnValue = 0;
            [result.data getBytes:&returnValue length:result.data.length];
    //        NSLog(@"[Controller sendCommand:] returnValue = %d", returnValue);
            if (returnValue == 1) {
                [[PopoverController shared].playlistTableController clearPlaylist];
            }
        }
    } else {
        if ([Server connectedCount:browser] <= 0) {
            [[PopoverController shared].playlistTableController clearPlaylist];
            return;
        }
        
        // Send to extensions
        [Server send:[self JSONForCommand:@"vkpc" data:command] forBrowser:browser];
    }
}

+ (NSString *)findRunningAppAndPrepareASForCommand:(NSString *)command {
    NSArray *list = browsers[browser];
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSDictionary *app;
    
    BOOL found = NO;
    for (int i = 0; i < apps.count; i++) {
        NSRunningApplication *currentApp = apps[i];
        
        for (NSDictionary *dict in list) {
            if ([currentApp.bundleIdentifier isEqualToString:dict[@"id"]]) {
                app = dict;
                found = YES;
                break;
            }
        }
        
        if (found)
            break;
    }
    
    if (!found) {
//        NSLog(@"[Controller findRunningAppAndPrepareASForCommand:] %@ not found in running applications, nil will returned", (NSString *)browsers[browser][0][@"name"]);
        return nil;
    }
    
    NSString *as = scriptAS;
    NSInteger playlistID = [PopoverController shared].playlistTableController.playlist.playlistID;
    
    NSString *ASExecuteJS, *ASCurrentTab, *ASTabTitle;
    if (browser == BrowserSafari) {
        ASExecuteJS = kASExecuteJSSafari;
        ASCurrentTab = kASCurrentTabSafari;
        ASTabTitle = kASTabTitleSafari;
    } else {
        ASExecuteJS = kASExecuteJSChrome;
        ASCurrentTab = kASCurrentTabChrome;
        ASTabTitle = kASTabTitleChrome;
    }
    
    as = [as stringByReplacingOccurrencesOfString:@"{appName}" withString:app[@"name"]];
    as = [as stringByReplacingOccurrencesOfString:@"{js}" withString:scriptJS];
    as = [as stringByReplacingOccurrencesOfString:@"{ASExecuteJS}" withString:ASExecuteJS];
    as = [as stringByReplacingOccurrencesOfString:@"{ASCurrentTab}" withString:ASCurrentTab];
    as = [as stringByReplacingOccurrencesOfString:@"{ASTabTitle}" withString:ASTabTitle];
    
    as = [as stringByReplacingOccurrencesOfString:@"{playlistID}" withString:[NSString stringWithFormat:@"%ld", playlistID]];
    as = [as stringByReplacingOccurrencesOfString:@"{command}" withString:command];
    
    return as;
}

+ (void)handleClient:(NSDictionary *)json {
//    NSLog(@"[Controller handleClient] json: %@", json);
    
    NSInteger fromBrowser = [(NSNumber *)json[@"_browser"] integerValue];
    if (fromBrowser != browser) {
//        NSLog(@"[Controller handleClient] received message from browser=%zd, but current browser=%zd, skipping", fromBrowser, browser);
        return;
    }
    
    NSString *command = json[@"command"];
    NSDictionary *data = json[@"data"];
    if (!command || [command isEqual:[NSNull null]]) {
        NSLog(@"[Controller handleCommand] !json");
        return;
    }
    
    if ([command isEqualToString:@"updatePlaylist"]) {
        NSArray *tracks = data[@"tracks"];
        NSInteger playlistId = [(NSNumber *)data[@"id"] intValue];
        NSString *title = data[@"title"];
        NSDictionary *active = data[@"active"];
        NSString *browser = data[@"browser"];
        
        NSString *activeStatus = active[@"status"];
        NSString *activeId = active[@"id"];
        BOOL playingStatus = ( activeStatus && ![activeStatus isEqual:[NSNull null]] && [activeStatus isEqualToString:@"play"] ) ? YES : NO;
        
        NSLog(@"[server] got updatePlaylist; id=%ld, activeId=%@, activeStatus=%@, browser=%@, title=%@",
              playlistId, (NSString *)active[@"id"], active[@"status"], browser, title);
        
        if ([[PopoverController shared].playlistTableController inited]) {
            NSLog(@"[Controller handleClient] call setPlaylist..");
            [[PopoverController shared].playlistTableController setPlaylistDataWithTracks:tracks title:title id:playlistId activeId:activeId activePlaying:playingStatus browser:browser];
        } else {
            NSLog(@"[Controller handleClient] call preSetPlaylist..");
            [PlaylistTableController preSetPlaylistDataWithTracks:tracks title:title id:playlistId  activeId:activeId activePlaying:playingStatus browser:browser];
        }
    } else if ([command isEqualToString:@"operateTrack"]) {
        NSString *trackId = data[@"id"];
        NSString *status = data[@"status"];
        NSInteger playlistId = [(NSNumber *)data[@"playlistId"] intValue];
        
        NSLog(@"[server] got operateTrack; trackId=%@, status=%@, plId=%ld",
              trackId, status, playlistId);
        
        PlayingStatus playingStatus = (status && ![status isEqual:[NSNull null]] && [status isEqualToString:@"play"]) ? PlayingStatusPlaying : PlayingStatusPaused;
        [[PopoverController shared].playlistTableController setPlayingTrackById:trackId withStatus:playingStatus forPlaylist:playlistId];
    } else if ([command isEqualToString:@"clearPlaylist"]) {
        [[PopoverController shared].playlistTableController clearPlaylist];
    }
}

// PlaylistDeletage
+ (void)playlistIDChanged:(NSInteger)playlistID {
//    NSLog(@"playlist id changed! new id: %zd", playlistID);
    if (initialized) {
//        NSLog(@"now send new playlist id to clients");
        [Server send:[self JSONForCommand:@"set_playlist_id" data:[NSNumber numberWithInteger:playlistID]] forBrowser:-1];
    }
}

// KVO
+ (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:VKPCPreferencesBrowser]) {
        NSNumber *new = change[NSKeyValueChangeKindKey];
        if ([new integerValue] == NSKeyValueChangeSetting) {
            NSInteger value = [(NSNumber *)change[NSKeyValueChangeNewKey] integerValue];
            if (browser != value) {
                NSLog(@"[Controller KVO] new browser is %@", browsers[value][0][@"name"]);
                browser = value;
                [cache removeAllObjects];
                [[PopoverController shared].playlistTableController clearPlaylist];
                [self setupTimer];
            }
        }
    }
}

// Other
+ (BOOL)isASBrowser:(NSInteger)browser {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesUseExtensionMode] && (
                                                                     browser == BrowserChrome
                                                                     || browser == BrowserYandex
                                                                     || browser == BrowserSafari );
}

+ (NSString *)JSONForCommand:(NSString *)command data:(NSObject *)data {
    NSDictionary *dict = @{@"command": command, @"data": data};
    NSError *error;
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:(NSJSONWritingOptions)0 error:&error];
    
    if (!json) {
        NSLog(@"[Controller JSONForCommand] error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    }
}

@end
