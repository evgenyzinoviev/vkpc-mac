//
//  CatchMediaButtons.m
//  VKPC
//
//  Created by Eugene on 10/22/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.

#import "CatchMediaButtons.h"
#import "MultiClickRemoteBehavior.h"
#import "SPMediaKeyTap.h"
#import "Controller.h"

static SPMediaKeyTap *keyTap;
static MultiClickRemoteBehavior *remoteBehavior;
static RemoteControl *remoteControl;
static BOOL started = NO;
static BOOL initialized = NO;

@implementation CatchMediaButtons

+ (void)initialize {
    if (initialized) {
        return;
    }
    
    keyTap = nil;
    [[NSUserDefaults standardUserDefaults] addObserver:(id)[self class]
                                            forKeyPath:VKPCPreferencesCatchMediaButtons
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:VKPCPreferencesCatchMediaButtons]) {
        [CatchMediaButtons start];
    }
    
    initialized = YES;
}

+ (void)start {
    NSLog(@"[CatchMediaButtons] start");
    
    if (started) {
        NSLog(@"[CatchMediaButtons] start: already started, calling stop first");
        [self stop];
    }
    
    if (keyTap == nil) {
        NSLog(@"[CatchMediaButtons] start: keyTap == nil, creating instance");
        
        keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
        
        remoteControl = [[AppleRemote alloc] initWithDelegate:self];
        [remoteControl setDelegate:self];
        
        remoteBehavior = [MultiClickRemoteBehavior new];
        [remoteBehavior setDelegate:self];
        [remoteControl setDelegate:remoteBehavior];
    }
    
    [keyTap startWatchingMediaKeys];
    [remoteControl startListening:self];
    
    NSLog(@"[CatchMediaButtons] started");
    started = YES;
}

+ (void)stop {
    NSLog(@"[CatchMediaButtons] stop");

    if (!started) {
        NSLog(@"[CatchMediaButtons] stop: not started");
        return;
    }
    
    [keyTap stopWatchingMediaKeys];
    [remoteControl stopListening:self];
    
    NSLog(@"[CatchMediaButtons] stopped");
    started = NO;
}

+ (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown clickCount:(unsigned int)clickCount {
    if (!pressedDown) {
        return;
    }
    
    switch(buttonIdentifier) {
        case kRemoteButtonPlay:
//            [self forAllPlay];
            break;
            
        case kRemoteButtonRight:
//            [self forAllNext];
            break;
            
        case kRemoteButtonLeft:
//            [self forAllPrev];
            break;
            
        default:
            break;
    }
}

+ (void)mediaKeyTap:(SPMediaKeyTap *)keyTap receivedMediaKeyEvent:(NSEvent *)event; {
    NSAssert(event.type == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    
    if (keyIsPressed) {
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                [Controller playpause];
                break;
                
            case NX_KEYTYPE_FAST:
                [Controller next];
                break;
                
            case NX_KEYTYPE_REWIND:
                [Controller prev];
                break;
                
            default:
                // More cases defined in hidsystem/ev_keymap.h
                break;
        }
    }
}

// KVO
+ (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:VKPCPreferencesCatchMediaButtons]) {
        NSNumber *new = change[NSKeyValueChangeKindKey];
        if ([new integerValue] == NSKeyValueChangeSetting) {
            BOOL value = [(NSNumber *)change[NSKeyValueChangeNewKey] boolValue];
            if (!value) {
                [CatchMediaButtons stop];
            } else {
                [CatchMediaButtons start];
            }
        }
    }
}

@end
