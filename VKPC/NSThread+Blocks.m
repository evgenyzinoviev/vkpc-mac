//
// NSThread+Blocks.m
// Shopify_Mobile
//
// Created by Matthew Newberry on 9/3/10.
// Copyright 2010 Shopify. All rights reserved.
//

#import "NSThread+Blocks.h"

@implementation NSThread (BlocksAdditions)

- (void)performBlock:(void (^)())block {
    if ([[NSThread currentThread] isEqual:self]) {
        block();
    } else {
        [self performBlock:block waitUntilDone:NO];
    }
}

- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait {
    [NSThread performSelector:@selector(ng_runBlock:)
                     onThread:self
                   withObject:block
                waitUntilDone:wait];
}

+ (void)ng_runBlock:(void (^)())block {
    block();
}

@end
