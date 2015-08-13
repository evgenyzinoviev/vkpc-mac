//
//  Queue.m
//  VKPC
//
//  Created by Eugene on 12/3/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import "Queue.h"
#import "NSMutableArray+QueueAdditions.h"

@implementation Queue

- (id)init {
    if (self = [super init]) {
        tasks = [[NSMutableArray alloc] init];
        active = false;
    }
    return self;
}

- (void)setHandler:(__strong id<QueueControllerProtocol>)val {
    handler = val;
}

- (void)addTask:(id)task {
    [tasks enqueue:task];
    
    if (!active) [self process];
}

- (void)process {
    if (active || ![tasks count]) return;
    
    active = true;
    id task = [tasks dequeue];
    [self passToHandler:task];
}

- (void)passToHandler:(__strong id)task {
    [handler onQueueTask:task forQueue:self];
}

- (void)taskDone {
    if (active) {
        active = false;
        [self process];
    }
}

@end
