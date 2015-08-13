//
//  NonVibrantButton.m
//  VKPC
//
//  Created by Eugene on 11/18/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "NonVibrantButton.h"

@implementation NonVibrantButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)allowsVibrancy {
    return NO;
}

@end
