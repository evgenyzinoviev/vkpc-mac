//
//  Queue.h
//  VKPC
//
//  Created by Eugene on 12/3/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QueueControllerProtocol.h"

@interface Queue : NSObject {
    __strong id<QueueControllerProtocol> handler;
    NSMutableArray *tasks;
    BOOL active;
}

- (void)setHandler:(__strong id<QueueControllerProtocol>)val;
- (void)addTask:(id)task;
- (void)process;
- (void)passToHandler:(id)task;
- (void)taskDone;

@end
