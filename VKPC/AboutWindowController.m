//
//  AboutWindowController.m
//  VKPC
//
//  Created by Eugene on 12/1/13.
//  Copyright (c) 2013 Eugene Z. All rights reserved.
//

#import "AboutWindowController.h"

static NSString * const ezURL = @"<a href=\"http://vk.com/ez\">vk.com/ez</a>";
static NSString * const ch1pURL = @"<a href=\"http://ch1p.com/vkpc/\">ch1p.com/vkpc/</a>";

@implementation AboutWindowController

- (BOOL)allowsClosingWithShortcut {
    return YES;
}

static void setStyleForAttributedString(NSMutableAttributedString *string) {
    NSRange range = NSMakeRange(0, string.length);
    
    NSFont *font = [NSFont fontWithName:GetSystemFontName() size:13.0];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    [paragraphStyle setLineSpacing:3];
    
    [string addAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName] range:range];
    [string addAttributes:[NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName] range:range];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Title
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleShortVersionString];
    if (VKPCIsDebug)
        version = [NSString stringWithFormat:@"%@ %@", version, @"dev"];
    
    NSString *title = [NSString stringWithFormat:@"%@ %@ (build %@)",
                       [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleDisplayName],
                       version,
                       [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion]];
    [_titleTextField setStringValue:title];
    
    NSDictionary *stringOptions = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                    NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)};

    // Copyright
//    NSMutableAttributedString *copyright = [[NSMutableAttributedString alloc] initWithHTML:[copyrightHTML dataUsingEncoding:NSUTF8StringEncoding]
//                                                                            options:stringOptions
//                                                                 documentAttributes:nil];
//    setStyleForAttributedString(copyright);
    
    
    // EZ Link
    NSMutableAttributedString *ez = [[NSMutableAttributedString alloc] initWithHTML:[ezURL dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:stringOptions
                                                                 documentAttributes:nil];
    setStyleForAttributedString(ez);
    [_ezTextField setAllowsEditingTextAttributes:YES];
    [_ezTextField setSelectable:YES];
    [_ezTextField setAttributedStringValue:ez];
    
    // CH1P Link
    NSMutableAttributedString *ch1p = [[NSMutableAttributedString alloc] initWithHTML:[ch1pURL dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:stringOptions
                                                                 documentAttributes:nil];
    setStyleForAttributedString(ch1p);
    [_ch1pTextField setAllowsEditingTextAttributes:YES];
    [_ch1pTextField setSelectable:YES];
    [_ch1pTextField setAttributedStringValue:ch1p];
    
//    [_copyrightTextField setAllowsEditingTextAttributes:YES];
//    [_copyrightTextField setSelectable:YES];
//    [_copyrightTextFie/ld setAttributedStringValue:copyright];
}

//- (IBAction)sendEmailAction:(id)sender {
//    NSString *encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@", [@"VK Player Controller" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    NSString *encodedTo = [CH1PEmail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    
//    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, @""];
//    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
//    
//    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
//}

@end
