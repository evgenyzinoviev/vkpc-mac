//
//  Server.h
//  VKPC
//
//  Created by Eugene on 11/29/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    unsigned long receivedLength;
    struct libwebsocket *wsi;
    char *buffer;
    NSInteger browser;
    char *commandToSend;
    unsigned long commandToSendLength;
} ServerSession;

@interface Server : NSObject

+ (void)start;
+ (BOOL)send:(NSString *)command forBrowser:(NSInteger)browser;
+ (NSThread *)thread;
+ (NSInteger)connectedCount:(NSInteger)browser;

@end