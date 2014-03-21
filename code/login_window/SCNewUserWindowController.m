//
//  SCNewUserWindowController.m
//  Poison
//
//  Created by stal on 1/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import "SCNewUserWindowController.h"
#import "SCAppDelegate.h"
#import "NSWindow+Shake.h"
#import "SCProfileManager.h"

@interface SCNewUserWindowController ()
@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSTextField *instructionLabel;
@property (strong) IBOutlet NSPanel *passwordSheetUnlock;
@property (strong) IBOutlet NSPanel *passwordSheetFirstTime;
@property (strong) IBOutlet NSButton *nextButton;
@end

@implementation SCNewUserWindowController

- (void)awakeFromNib {
    self.header.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.header.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.header.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.header.dragsWindow = YES;
    self.footer.backgroundColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.footer.shadowColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
    self.nameField.delegate = self;
}

- (void)windowDidLoad {
    self.window.delegate = self;
}

- (IBAction)submitPassword:(id)sender {
    //[(SCAppDelegate*)[NSApp delegate] makeApplicationReadyForToxing:NULL name:@"Toxicle"];
    if ([SCProfileManager profileNameExists:self.nameField.stringValue]) {
        [NSApp beginSheet:self.passwordSheetUnlock modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
    } else {
        [NSApp beginSheet:self.passwordSheetFirstTime modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
    }
    /*[self.window shakeWindow:^{
        [self.nameField becomeFirstResponder];
        [self.nameField selectText:self];
    }];*/
}

- (void)tryAutomaticLogin:(NSString *)name {
    self.nameField.stringValue = name;

}

- (IBAction)testPassword:(id)sender {

}

- (void)controlTextDidChange:(NSNotification *)obj {
    if ([SCProfileManager profileNameExists:self.nameField.stringValue])
        self.nextButton.title = NSLocalizedString(@"Log in", nil);
}

- (BOOL)windowShouldClose:(id)sender {
    return YES;
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

@end
