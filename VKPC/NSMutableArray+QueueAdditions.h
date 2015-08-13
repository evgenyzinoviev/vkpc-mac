//
//  NSMutableArray+QueueAdditions.h
//  VKPC
//
//  Created by Eugene on 12/3/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

@interface NSMutableArray (QueueAdditions)
- (id) dequeue;
- (void) enqueue:(id)obj;
@end