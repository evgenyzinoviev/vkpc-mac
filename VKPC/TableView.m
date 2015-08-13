//
//  TableView.m
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import "TableView.h"

@implementation TableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
