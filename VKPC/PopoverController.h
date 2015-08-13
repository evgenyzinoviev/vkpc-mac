//
//  PopoverController.h
//  VKPC
//
//  Created by Eugene on 11/30/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/SUUpdater.h>

@class PlaylistTableView, FlippedView, Popover, AboutWindowController, PreferencesWindowController, ShadowTextFieldCell, VibrantTextField, VibrantButton;

@interface PopoverController : NSViewController

@property (strong) IBOutlet NSArrayController *playlistArrayController;
@property (weak) IBOutlet VibrantTextField *titleTextField;
@property (weak) IBOutlet ShadowTextFieldCell *titleTextFieldCell;
@property (strong) IBOutlet NSMenu *browserMenu;
@property (strong) IBOutlet NSMenu *appMenu;
//@property (weak) IBOutlet FlippedView *_view;
@property (weak) IBOutlet PlaylistTableView *playlistTableView;
@property (weak) IBOutlet NSView *customView;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSImageCell *titleSeparatorImageCell;
@property (weak) IBOutlet NSButtonCell *settingsButtonCell;
@property (weak) IBOutlet VibrantButton *settingsButton;
@property (strong) IBOutlet FlippedView *view;

// Placeholder and system configuration button
@property (weak) IBOutlet VibrantTextField *playlistNotLoadedTextField;
//@property (weak) IBOutlet NSButton *systemConfigurationRequiredButton;

// Settings menu outlets
@property (weak) IBOutlet NSMenuItem *menuItemShowNotifications;
@property (weak) IBOutlet NSMenuItem *menuItemInvert;
@property (weak) IBOutlet NSMenuItem *menuItemCatch;
@property (weak) IBOutlet NSMenuItem *menuItemAutostart;

@property (strong) PlaylistTableController *playlistTableController;
@property (assign, nonatomic) PopoverState state;

/*@property (weak) IBOutlet NSMenuItem *menuItemBrowserChrome;
@property (weak) IBOutlet NSMenuItem *menuItemBrowserFirefox;
@property (weak) IBOutlet NSMenuItem *menuItemBrowserSafari;
@property (weak) IBOutlet NSMenuItem *menuItemBrowserOpera;
@property (weak) IBOutlet NSMenuItem *menuItemBrowserYandex;*/
@property (strong) IBOutlet SUUpdater *sparkleUpdater;
@property (weak) IBOutlet NSMenuItem *useExtensionMode;
@property (weak) IBOutlet NSMenuItem *downloadExtensionsMenuItem;

+ (PopoverController *)shared;

// Actions
- (IBAction)menuButtonAction:(id)sender;
- (IBAction)systemConfigurationRequiredAction:(id)sender;

// Settings actions
- (IBAction)menuItemShowNotificationsAction:(id)sender;
- (IBAction)menuItemInvertAction:(id)sender;
- (IBAction)menuItemCatchAction:(id)sender;
- (IBAction)menuItemAutostartAction:(id)sender;
- (IBAction)menuItemAboutAction:(id)sender;
- (IBAction)menuItemQuitAction:(id)sender;
- (IBAction)menuItemBrowserAction:(id)sender;
- (IBAction)menuItemDownloadExtensionsAction:(id)sender;
- (IBAction)menuItemCheckForUpdatesAction:(id)sender;
- (IBAction)useExtensionModeAction:(id)sender;

//- (void)initPlaceholder;
//- (void)initPlaylist;
- (void)resizeWithContentHeight:(int)height;
- (void)doResizeWithContentHeight:(int)height animate:(BOOL)animate;
- (void)popoverDidShow;
- (void)popoverDidHide;
- (void)updateTitle:(NSString *)title;
- (void)setState:(PopoverState)state;

@end
