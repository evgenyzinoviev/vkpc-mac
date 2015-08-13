//
//  HostsHackWindowController.m
//  VKPC
//
//  Created by Eugene on 10/30/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "HostsHackWindowController.h"
#import "HostsHack.h"

// TODO rewrite using normal coords

@implementation HostsHackWindowController {
    NSMutableAttributedString *configurationRequired;
    NSView *contentView;
}

- (BOOL)allowsClosingWithShortcut {
    return YES;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    contentView = self.window.contentView;
    
    NSTextFieldCell *cell = (NSTextFieldCell *)_configurationRequiredTextField.cell;
    NSString *configurationTextHTML = [NSString stringWithFormat:
                                       @"<html><span style=\"font-family: %@;\">"
                                            "<span style=\"line-height: 10px; font-size: 14px\"><b>Welcome to VK Player Controller!</b></span>"
                                            "<span style=\"font-size: 6px\"><br/><br/></span>"
                                            "<span style=\"font-size: 13px\">"
                                                "Let's make one magic trick with system DNS settings, it's necessary for a proper work of VK Player Controller. Don't worry, <b>it's absolutely safe</b>. Please press <b>Continue</b> button below."
//                                                "For VK Player Controller to work it is necessary to do some hacking with DNS resolution configuration. Press <b>Continue</b> to continue."
                                            "</span>"
                                            "<span style=\"font-size: 7px\"><br/><br/></span>"
                                            "<span style=\"font-size: 12px; color: #707070;\">"
                                                "The app modifies the file <b>%@</b>. If you don't trust us, open that file manually with admin privileges, add this line: <b>127.0.0.1\t%@</b>, save it and relaunch the app."
                                            "</span>"
                                        "</span></html>",
                                        //GetSystemFontName(),
                                       @"Helvetica Neue",
                                       [NSString stringWithUTF8String:VKPCHostsFile],
                                       [NSString stringWithUTF8String:VKPCWSClientHost]];
    
    configurationRequired = [[NSMutableAttributedString alloc] initWithHTML:[configurationTextHTML dataUsingEncoding:NSUTF8StringEncoding]
                                                                                               options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                                         NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                                    documentAttributes:nil];
    
    [_configurationRequiredTextField setAttributedStringValue:configurationRequired];
    [cell setWraps:YES];
    
    // Position text
    NSRect textFrame = _configurationRequiredTextField.frame;
    float textHeight = [configurationRequired boundingRectWithSize:CGSizeMake(textFrame.size.width, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading].size.height;
    textFrame.origin.y += textFrame.size.height - textHeight;
    textFrame.size.height = textHeight;
    [_configurationRequiredTextField setFrame:textFrame];

    // Position button
    NSRect buttonFrame = _button.frame;
    float padding = contentView.frame.size.height - (textFrame.origin.y + textFrame.size.height);
    float buttonPadding = 20;
    float buttonY = [self.window.contentView frame].size.height - textHeight - padding * 2 - buttonFrame.size.height;
    buttonFrame.origin.y = buttonY;
    [_button setFrame:buttonFrame];
    
    float windowHeight = contentView.frame.size.height - buttonFrame.origin.y + padding + buttonPadding;
    NSRect windowFrame = self.window.frame;
    windowFrame.origin.y += windowFrame.size.height;
    windowFrame.origin.y -= windowHeight;
    windowFrame.size.height = windowHeight;
    [self.window setFrame:windowFrame display:YES];
}

- (void)setButtonContinue {
    [_button setTitle:@"Continue"];
    [_button setEnabled:YES];
}

- (void)setButtonRetry {
    [_button setTitle:@"Retry"];
    [_button setEnabled:YES];
}

- (void)setButtonWait {
    [_button setTitle:@"Please wait.."];
    [_button setEnabled:NO];
}

- (IBAction)buttonPressed:(id)sender {
    [HostsHack hack];
}

- (void)showWindow:(id)sender {
    [self setButtonContinue];
    
    [super showWindow:sender];
    
    [self.window setDefaultButtonCell:_button.cell];
}

@end
