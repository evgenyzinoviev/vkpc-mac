//
//  NSMutableArray+QueueAdditions.m
//  VKPC
//
//  Created by Eugene on 12/3/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import "NSMutableArray+QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

- (id) dequeue {
    id headObject = [self objectAtIndex:0];
    if (headObject != nil) {
        [self removeObjectAtIndex:0];
    }
    return headObject;
}

- (void) enqueue:(id)anObject {
    [self addObject:anObject];
}

@end