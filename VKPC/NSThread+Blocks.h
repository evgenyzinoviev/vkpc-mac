//
//  NSThead+Blocks.h
//  VKPC
//
//  Created by Eugene on 11/7/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

@interface NSThread (BlocksAdditions)

- (void)performBlock:(void (^)())block;
- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait;

@end
