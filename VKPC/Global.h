//
//  global.h
//  VKPC
//
//  Created by Eugene on 11/28/13.
//  Copyright (c) 2013-2014 Eugene Z. All rights reserved.
//

#import "PlaylistTableController.h"

// Variables
extern int const VKPCHTTPServerPort;
extern NSString * const VKPCHTTPServerHost;

extern int const VKPCWSServerPort;
extern char * const VKPCWSServerHost;
extern char * const VKPCWSClientHost;
//extern char * const VKPCHostsFile;

extern NSString * const VKPCAppHomeURL;
extern NSString * const CH1PEmail;

extern BOOL const VKPCIsDebug;
extern BOOL const VKPCIsServerLogsEnabled;
extern BOOL VKPCIsYosemite;

extern NSString * const VKPCEZCopyright;
extern NSString * const VKPCEZCopyrightYears;
extern NSString * const VKPCEZURL;

extern NSString * const VKPCPreferencesShowNotifications;
extern NSString * const VKPCPreferencesInvertPlaylistIcons;
extern NSString * const VKPCPreferencesCatchMediaButtons;
extern NSString * const VKPCPreferencesBrowser;
extern NSString * const VKPCPreferencesStatisticReportedTimestamp;
extern NSString * const VKPCPreferencesUUID;
extern NSString * const VKPCPreferencesUseExtensionMode;

extern int VKPCSessionID;
//extern PlaylistTableController *VKPCPlaylistTableController;
extern pid_t VKPCPID;

extern NSString * const VKPCImageEmpty;
extern NSString * const VKPCImageCellBg;
extern NSString * const VKPCImageCellPressedBg;
extern NSString * const VKPCImagePause;
extern NSString * const VKPCImagePlay;
extern NSString * const VKPCImageTitleSeparator;
extern NSString * const VKPCImageSettings;
extern NSString * const VKPCImageSettingsPressed;
extern NSString * const VKPCImageStatus;
extern NSString * const VKPCImageStatusPressed;

extern NSString * const kAppleInterfaceStyle;
extern NSString * const kAppleInterfaceStyleDark;
extern NSString * const kAppleInterfaceThemeChangedNotification;
extern NSString * const kCFBundleDisplayName;
extern NSString * const kCFBundleShortVersionString;
extern NSString * const kCFBundleVersion;

// Functions
void VKPCInitGlobals();
void VKPCInitUUID();
void ShowNotification();
NSString * GetFileFromResourceAsString(NSString *fileName, NSError * __autoreleasing *error);
NSString *GetSystemFontName();
//BOOL IsDarkMode();
InterfaceStyle GetInterfaceStyle();
NSDictionary * VKPCGetImagesDictionary();
void DebugLog(const char *str);
long GetTimestamp();
BOOL IsAnotherProcessRunning();