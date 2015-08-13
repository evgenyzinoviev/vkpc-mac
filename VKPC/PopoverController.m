//
//  PopoverViewController.m
//  VKPC
//
//  Created by Eugene on 11/30/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "Popover.h"
#import "PopoverController.h"
#import "FlippedView.h"
#import "AboutWindowController.h"
#import "PlaylistTableController.h"
#import "NSMutableArray+QueueAdditions.h"
#import "Controller.h"
//#import "HostsHack.h"
#import "Playlist.h"
#import "Server.h"
#import "Autostart.h"
#import "CatchMediaButtons.h"
#import "Statistics.h"

#import "PlaylistTableView.h"
#import "PlaylistTableCellView.h"
#import "ShadowTextFieldCell.h"
#import "VibrantTextField.h"

static const int kMinPopoverHeight = 240;
static const int kMaxPopoverHeight = 480;

static NSInteger NSStateFromBool(BOOL v) {
    return v ? NSOnState : NSOffState;
}
static BOOL BoolFromNSState(NSInteger state) {
    return state == NSOffState ? NO : YES;
}
static NSInteger InvertNSState(NSInteger state) {
    return state == NSOffState ? NSOnState : NSOffState;
}

@implementation PopoverController {
    int setHeightOnShow;
    AboutWindowController *aboutWindowController;
}

+ (PopoverController *)shared {
    static PopoverController *shared = nil;
    @synchronized (self) {
        if (shared == nil){
            shared = [[self alloc] initWithNibName:@"PopoverView" bundle:nil];
        }
    }
    return shared;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _state = PopoverStatePlaylistNotLoaded;
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"[PopoverController awakeFromNib]");
    
    [super awakeFromNib];
    [self updateStyle];
    
    // Load settings
    BOOL catchMediaButtons = [[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesCatchMediaButtons];
    BOOL invertPlaylistIcons = [[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesInvertPlaylistIcons];
    BOOL showNotifications = [[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesShowNotifications];
    BOOL launchOnStartup = [Autostart isLaunchAtStartup];
    BOOL useExtensionMode = [[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesUseExtensionMode];
    NSInteger browser = [[NSUserDefaults standardUserDefaults] integerForKey:VKPCPreferencesBrowser];
    
    [_menuItemCatch setState:NSStateFromBool(catchMediaButtons)];
    [_menuItemInvert setState:NSStateFromBool(invertPlaylistIcons)];
    [_menuItemShowNotifications setState:NSStateFromBool(showNotifications)];
    [_menuItemAutostart setState:NSStateFromBool(launchOnStartup)];
    [_useExtensionMode setState:NSStateFromBool(useExtensionMode)];
    [self useExtensionModeUpdated];
    
    if (browser < [_browserMenu itemArray].count && browser >= 0) {
        [(NSMenuItem *)[_browserMenu itemArray][browser] setState:NSOnState];
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:VKPCPreferencesBrowser];
        [(NSMenuItem *)[_browserMenu itemArray][0] setState:NSOnState];
    }
    
    //
    _playlistTableController = [[PlaylistTableController alloc] init];
    setHeightOnShow = -1;
    
    if (VKPCIsYosemite) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeChanged:) name:kAppleInterfaceThemeChangedNotification object:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:VKPCPreferencesInvertPlaylistIcons
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    [self updateState];
    
#ifdef DEBUG
    NSArray *debugMenuItems = @[
        [[NSMenuItem alloc] initWithTitle:@"Inject script" action:@selector(menuInjectAction:) keyEquivalent:@"inject"],
        [[NSMenuItem alloc] initWithTitle:@"Send 'play' command" action:@selector(menuSendPlayAction:) keyEquivalent:@"send_play"],
        [[NSMenuItem alloc] initWithTitle:@"JS to clipboard" action:@selector(menuJSToClipboardAction:) keyEquivalent:@"copy_js"],
        [[NSMenuItem alloc] initWithTitle:@"AS to clipboard" action:@selector(menuASToClipboardAction:) keyEquivalent:@"copy_as"],
        [[NSMenuItem alloc] initWithTitle:@"Notification after 1 sec" action:@selector(menuNotificationAction:) keyEquivalent:@"notification"],
        [[NSMenuItem alloc] initWithTitle:@"Add tracks" action:@selector(menuAddTracksAction:) keyEquivalent:@"add_tracks"],
        [[NSMenuItem alloc] initWithTitle:@"Remove tracks" action:@selector(menuRemoveTracksAction:) keyEquivalent:@"remove_tracks"],
//        [[NSMenuItem alloc] initWithTitle:@"Show HH window" action:@selector(menuShowHHWindowAction:) keyEquivalent:@"show_hh"],
        [[NSMenuItem alloc] initWithTitle:@"Print debug info" action:@selector(menuPrintDebugInfoAction:) keyEquivalent:@"print_debug_info"],
        [[NSMenuItem alloc] initWithTitle:@"Something" action:@selector(menuSomethingAction:) keyEquivalent:@"something"]
    ];

    for (NSMenuItem *item in debugMenuItems) {
        [_appMenu insertItem:item atIndex:[_appMenu itemArray].count-3];
    }
    [_appMenu insertItem:[NSMenuItem separatorItem] atIndex:[_appMenu itemArray].count-3];
#endif
}

// UI

- (void)setState:(PopoverState)state {
    _state = state;
    [self updateState];
}

- (void)updateState {
    switch (_state) {
        case PopoverStatePlaylistNotLoaded:
            [_customView setHidden:NO];
//            [_systemConfigurationRequiredButton setHidden:YES];
            [_playlistNotLoadedTextField setHidden:NO];
            break;
            
        case PopoverStatePlaylistLoaded:
            [_customView setHidden:YES];
            break;
            
        case PopoverStateSystemConfigurationRequired:
            [_customView setHidden:NO];
            [_playlistNotLoadedTextField setHidden:YES];
//            [_systemConfigurationRequiredButton setHidden:NO];
            break;
    }
}

- (void)resizeWithContentHeight:(int)height {
    NSPopover *popover = [[Popover shared] popover];
    if (!popover.isShown)
        setHeightOnShow = height;
    //else
    [self doResizeWithContentHeight:height animate:popover.isShown];
}

- (void)doResizeWithContentHeight:(int)height animate:(BOOL)animate {
    NSRect scrollViewFrame = self.scrollView.frame;
    int scrollViewYOffset = scrollViewFrame.origin.y;
    
    int popoverHeight = height + scrollViewYOffset;
    if (popoverHeight > kMaxPopoverHeight) popoverHeight = kMaxPopoverHeight;
    if (popoverHeight < kMinPopoverHeight) popoverHeight = kMinPopoverHeight;
    
    NSSize popoverSize = [[Popover shared] getSize];
    [[Popover shared] setSize:NSMakeSize(popoverSize.width, popoverHeight) animate:animate];
    [[self scrollView] setFrame:NSMakeRect(scrollViewFrame.origin.x, scrollViewFrame.origin.y, scrollViewFrame.size.width, popoverHeight-scrollViewYOffset)];
}

- (void)updateStyle {
    NSDictionary *images = VKPCGetImagesDictionary();
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *bold = [fontManager fontWithFamily:GetSystemFontName() traits:NSUnitalicFontMask weight:9 size:13.0];
    
    VibrantTextField *ph = [[[self customView] subviews] objectAtIndex:0];
    
    switch (GetInterfaceStyle()) {
        case InterfaceStyleLegacy:
            // title
            [_titleTextField setTextColor:[NSColor colorWithSRGBRed:0.498 green:0.51 blue:0.522 alpha:1]];
            
            // placeholder
            [ph setTextColor:[NSColor colorWithSRGBRed:0.612 green:0.624 blue:0.631 alpha:1]];
            break;
            
        case InterfaceStyleYosemite:
            // title
            [_titleTextFieldCell setTextColor:[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.32]];
            
            // placeholder
            [ph setTextColor:[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.2]];
            break;
            
        case InterfaceStyleYosemiteDark:
            // title
            [_titleTextField setTextColor:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.5]];
            
            // placeholder
            [ph setTextColor:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.2]];
            break;
    }
    
    [_titleTextField setFont:bold];
    
    [_titleSeparatorImageCell setImage:images[VKPCImageTitleSeparator]];
    [_settingsButtonCell setImage:images[VKPCImageSettings]];
    [_settingsButtonCell setAlternateImage:images[VKPCImageSettingsPressed]];
}

- (void)updateTitle:(NSString *)title {
    if ([title isEqualToString:@""]) {
        title = [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleDisplayName];
    }
    [_titleTextField setStringValue:title];
}

- (IBAction)menuButtonAction:(id)sender {
    [NSMenu popUpContextMenu:_appMenu
                   withEvent:[NSApp currentEvent]
                     forView:sender];
}

//- (IBAction)systemConfigurationRequiredAction:(id)sender {
//    [[Popover shared] hidePopover];
//    [HostsHack showWindow];
//}

- (IBAction)menuItemAboutAction:(id)sender {
    if (!aboutWindowController) {
        aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindow"];
    }
    [aboutWindowController showWindow:nil];
    [aboutWindowController.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    
    [[Popover shared] hidePopover];
}

- (IBAction)menuItemQuitAction:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)menuItemShowNotificationsAction:(id)sender {
    NSInteger newState = InvertNSState(_menuItemShowNotifications.state);
    [_menuItemShowNotifications setState:newState];
    [[NSUserDefaults standardUserDefaults] setBool:BoolFromNSState(newState) forKey:VKPCPreferencesShowNotifications];
}

- (IBAction)menuItemInvertAction:(id)sender {
    NSInteger newState = InvertNSState(_menuItemInvert.state);
    [_menuItemInvert setState:newState];
    [[NSUserDefaults standardUserDefaults] setBool:BoolFromNSState(newState) forKey:VKPCPreferencesInvertPlaylistIcons];
}

- (IBAction)menuItemCatchAction:(id)sender {
    NSInteger newState = InvertNSState(_menuItemCatch.state);
    [_menuItemCatch setState:newState];
    [[NSUserDefaults standardUserDefaults] setBool:BoolFromNSState(newState) forKey:VKPCPreferencesCatchMediaButtons];
}

- (IBAction)menuItemAutostartAction:(id)sender {
    BOOL status = [Autostart isLaunchAtStartup];
    [Autostart toggleLaunchAtStartup];
    [_menuItemAutostart setState:NSStateFromBool(!status)];
}

#ifdef DEBUG
- (IBAction)menuInjectAction:(id)sender {
    [Controller debugInject];
}

- (IBAction)menuSendPlayAction:(id)sender {
    [Controller debugSendPlay];
}

- (IBAction)menuJSToClipboardAction:(id)sender {
    [Controller debugCopyJS];
}

- (IBAction)menuASToClipboardAction:(id)sender {
    [Controller debugCopyAS];
}

- (IBAction)menuNotificationAction:(id)sender {
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(showTestNotification)
                                   userInfo:nil
                                    repeats:NO];
    [[Popover shared] hidePopover];
}

- (void)showTestNotification {
    ShowNotification(@"Title", @"Text");
}

//- (IBAction)menuShowHHWindowAction:(id)sender {
//    [[Popover shared] hidePopover];
//    [HostsHack showWindow];
//}

- (IBAction)menuAddTracksAction:(id)sender {
    for (int i = 0; i < 1000; i++)
        [_playlistTableController.playlist.tracks addObject:@{
           @"id": @"0_0",
           @"artist": [@"Within Temptation " stringByAppendingString:[NSString stringWithFormat:@"%d", i]],
           @"title": [@"Promise " stringByAppendingString:[NSString stringWithFormat:@"%d", i]],
           @"duration": @"7:25",
           @"playImage": VKPCGetImagesDictionary()[VKPCImageEmpty]
           }];
    [_playlistTableController playlistUpdated];
}

- (IBAction)menuRemoveTracksAction:(id)sender {
    [_playlistTableController clearPlaylist];
//    [_playlistTableController.playlist.tracks removeAllObjects];
//    [_playlistTableController playlistUpdated];
}

- (IBAction)menuPrintDebugInfoAction:(id)sender {
    for (int i = 0; i < 5; i++) {
        NSLog(@"[DEBUG INFO] browserid=%d, connected=%zd", i, [Server connectedCount:i]);
    }
    if (_playlistTableController) {
        NSLog(@"[DEBUG_INFO] playlist id: %zu", _playlistTableController.playlist.playlistID);
    }
    NSLog(@"[DEBUG_INFO] sid: %d", VKPCSessionID);
}

- (IBAction)menuSomethingAction:(id)sender {
//    for (int i = 0; i < 20; i++) {
//        [CatchMediaButtons stop];
//        [CatchMediaButtons start];
//    }
//    NSLog(@"timestamp: %ld\n", GetTimestamp());
//    NSLog(@"another timestamp: %lf\n", [[NSDate date] timeIntervalSince1970]);
// /   NSLog(@"UUID: %@", [[NSUserDefaults standardUserDefaults] stringForKey:VKPCPreferencesUUID]);
    [Statistics initialize];
}
#endif

- (IBAction)menuItemBrowserAction:(id)sender {
    NSMenuItem *item = (NSMenuItem *)sender;
    NSInteger index = [[_browserMenu itemArray] indexOfObject:item];
    
    for (int i = 0; i < BrowsersCount; i++) {
        if (i != index) {
            [(NSMenuItem *)[_browserMenu itemArray][i] setState:NSOffState];
        } else {
            [item setState:NSOnState];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:VKPCPreferencesBrowser];
}

- (IBAction)menuItemDownloadExtensionsAction:(id)sender {
    [[Popover shared] hidePopover];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://ch1p.com/vkpc/#extensions"]];
}

- (IBAction)menuItemCheckForUpdatesAction:(id)sender {
    [[Popover shared] hidePopover];
    [_sparkleUpdater checkForUpdates:sender];
}

- (IBAction)useExtensionModeAction:(id)sender {
    BOOL use = BoolFromNSState(((NSMenuItem *)sender).state);
    [_useExtensionMode setState:NSStateFromBool(!use)];
    [[NSUserDefaults standardUserDefaults] setBool:BoolFromNSState(!use) forKey:VKPCPreferencesUseExtensionMode];
    [self useExtensionModeUpdated];
}

- (void)useExtensionModeUpdated {
    BOOL use = BoolFromNSState(_useExtensionMode.state);
    [_downloadExtensionsMenuItem setTitle:( use ? @"Download extensions" : @"Extensions for Firefox and Opera" )];
}

//#if !IS_PRODUCTION
//
//- (IBAction)onSettingsItemTestAddTracksClick:(id)sender {
//    [playlistTableController testAddTracks];
//}
//
//- (IBAction)onSettingsItemTestRemoveAllTracksClick:(id)sender {
//    [playlistTableController testRemoveAllTracks];
//}
//
//- (IBAction)onSettingsItemTestResizePopoverClick:(id)sender {
//    NSSize popoverSize = [[self statusItemPopup] getSize];
//    int add = 100;
//    
//    [[self statusItemPopup] setSize:NSMakeSize(popoverSize.width, popoverSize.height+add) animate:YES];
//}
//
//- (IBAction)onSettingsItemTestPrintDebugInfoClick:(id)sender {
//    NSRect rect = [[self _view] frame], scrollRect = [[self scrollView] frame];
//    NSLog(@"[view] x: %f, y: %f, width: %f, height: %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//    NSLog(@"[scrollView] x: %f, y: %f, width: %f, height: %f", scrollRect.origin.x, scrollRect.origin.y, scrollRect.size.width, scrollRect.size.height);
//}
//
//# endif

- (void)popoverDidShow {
    [_scrollView setHidden:NO];
    if (setHeightOnShow != -1) {
        [self doResizeWithContentHeight:setHeightOnShow animate:NO];
        setHeightOnShow = -1;
    }
}

- (void)popoverDidHide {
    [_scrollView setHidden:YES];
}

- (void)darkModeChanged:(NSNotification *)notification {
    [self updateStyle];
    
    for (int i = 0; i < _playlistTableView.numberOfRows; i++) {
        [[_playlistTableController getCellViewForIndex:i] updateStyle];
    }
}

- (void)invertPrefChanged {
    Playlist *playlist = _playlistTableController.playlist;
    PlayingTrackStatus playing = playlist.playing;
    NSInteger index = playing.index;
    
    if (index < _playlistTableView.numberOfRows) {
        [[_playlistTableController getCellViewForIndex:index] drawMode];
    }
}

// KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:VKPCPreferencesInvertPlaylistIcons]) {
        NSNumber *new = change[NSKeyValueChangeKindKey];
        if ([new integerValue] == NSKeyValueChangeSetting) {
            [self invertPrefChanged];
        }
    }
}

@end
