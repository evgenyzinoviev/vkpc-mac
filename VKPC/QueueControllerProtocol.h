//
//  QueueProtocol.h
//  VKPC
//
//  Created by Eugene on 12/3/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

@class Queue;

@protocol QueueControllerProtocol <NSObject>

- (void)onQueueTask:(id)task forQueue:(Queue *)queue;

@end
