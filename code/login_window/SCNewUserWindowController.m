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
#import <Security/Security.h>

#define SERVICE_NAME "Tox (ca.kirara.poison.next)"
#define SERVICE_NAME_LENGTH (27)

void *const SCAlertEndingShowPassword;

@interface NSString (SCNewUserWindowController_Ext)
- (NSString *)strippedValue;
- (BOOL)isValidLoginName;
@end
@implementation NSString (SCNewUserWindowController_Ext)

- (NSString *)strippedValue {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isValidLoginName {
    return ![self.strippedValue isEqualToString:@""];
}

@end

@interface SCNewUserWindowController ()
@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSTextField *instructionLabel;
@property (strong) IBOutlet NSPanel *passwordSheetUnlock;
@property (strong) IBOutlet NSPanel *passwordSheetFirstTime;
@property (strong) IBOutlet NSButton *nextButton;
#pragma mark - Sheet with one field
@property (strong) IBOutlet NSTextField *unlockSheetTitle;
@property (strong) IBOutlet NSSecureTextField *rPassword;
@property (strong) IBOutlet NSButton *keychainCheck1;
#pragma mark - Sheet with two fields
@property (strong) IBOutlet NSTextField *ftFlavourText;
@property (strong) IBOutlet NSSecureTextField *ftPassword1;
@property (strong) IBOutlet NSSecureTextField *ftPassword2;
@property (strong) IBOutlet NSButton *keychainCheck2;

@property BOOL shouldUseKeychain;
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
    self.instructionLabel.stringValue = SCLocalizedFormatString(@"Welcome to %@. Enter a nickname to get started.", nil, SCApplicationInfoDictKey(@"CFBundleName"));
}

- (void)windowDidLoad {
    self.window.delegate = self;
}

#pragma mark - Keychain stuff

- (void)savePasswordInKeychain:(NSString *)pass forName:(NSString *)name {
    const char *account = [name UTF8String];
    NSUInteger alen = [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    const char *password = [pass UTF8String];
    NSUInteger plen = [pass lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    SecKeychainAddGenericPassword(NULL, SERVICE_NAME_LENGTH, SERVICE_NAME,
                                  (UInt32)alen, account, (UInt32)plen, password, NULL);
}

- (NSString *)passwordFromKeychainForName:(NSString *)name {
    const char *account = [name UTF8String];
    NSUInteger alen = [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    uint8_t *password = NULL;
    uint32_t length = 0;
    OSStatus err = SecKeychainFindGenericPassword(NULL, SERVICE_NAME_LENGTH, SERVICE_NAME,
                                                  (uint32_t)alen, account, &length, (void**)&password, NULL);
    if (err != errSecSuccess) {
        NSLog(@"note: password couldn't be fetched from keychain, %d", err);
        return nil;
    } else {
        return [[NSString alloc] initWithBytesNoCopy:password
                                              length:length
                                            encoding:NSUTF8StringEncoding
                                        freeWhenDone:YES];
    }
}

- (IBAction)submitPassword:(id)sender {
    //[(SCAppDelegate*)[NSApp delegate] makeApplicationReadyForToxing:NULL name:@"Toxicle"];
    NSString *name = self.nameField.stringValue.strippedValue;
    if (!name.isValidLoginName) {
        [self failed:NSLocalizedString(@"You can't leave the name blank.", @"")];
        return;
    }
    if ([SCProfileManager profileNameExists:name]) {
        self.unlockSheetTitle.stringValue = SCLocalizedFormatString(@"Enter the password to unlock the profile \"%@\".", nil, name);
        NSString *pass = [self passwordFromKeychainForName:name];
        if (pass) {
            NSError *error = nil;
            txd_intermediate_t data = [SCProfileManager attemptDecryptionOfProfileName:name password:pass error:&error];
            if (!data) {
                NSAlert *alert = [NSAlert alertWithMessageText:error.localizedDescription
                                                 defaultButton:NSLocalizedString(@"Dismiss", nil)
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@""];
                alert.informativeText = error.localizedFailureReason;
                [alert beginSheetModalForWindow:self.window
                                  modalDelegate:self
                                 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                    contextInfo:SCAlertEndingShowPassword];
            } else {
                [(SCAppDelegate *)[NSApp delegate] makeApplicationReadyForToxing:data
                                                                            name:name
                                                                        password:pass];
            }
        } else {
            [NSApp beginSheet:self.passwordSheetUnlock modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
        }
    } else {
        [NSApp beginSheet:self.passwordSheetFirstTime modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)tryAutomaticLogin:(NSString *)name {
    self.nameField.stringValue = name.strippedValue;
    [self submitPassword:self];
}

#pragma mark - UI handling

- (IBAction)testPassword:(id)sender {
    if (self.shouldUseKeychain) {
        [self savePasswordInKeychain:self.rPassword.stringValue forName:self.nameField.stringValue.strippedValue];
    }
    NSError *err = nil;
    txd_intermediate_t profile = [SCProfileManager attemptDecryptionOfProfileName:self.nameField.stringValue
                                                                         password:self.rPassword.stringValue
                                                                            error:&err];
    [NSApp endSheet:((NSView *)sender).window];
    if (profile) {
        [NSApp endSheet:((NSView *)sender).window];
        [(SCAppDelegate *)[NSApp delegate] makeApplicationReadyForToxing:profile
                                                                    name:self.nameField.stringValue
                                                                password:self.rPassword.stringValue];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:err.localizedDescription
                                         defaultButton:NSLocalizedString(@"Dismiss", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        alert.informativeText = err.localizedFailureReason;
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:SCAlertEndingShowPassword];
    }
}

- (IBAction)makeNewProfile:(id)sender {
    if ([self.ftPassword1.stringValue length] < 6) {
        [self.window shakeWindow:^{
            self.ftPassword2.stringValue = @"";
            [self.ftPassword1 becomeFirstResponder];
            [self.ftPassword1 selectText:self];
            self.ftFlavourText.stringValue = NSLocalizedString(@"Please use a longer password. Your personal identity is at stake here!", @"");
        }];
    } else if (![self.ftPassword1.stringValue isEqualToString:self.ftPassword2.stringValue]) {
        [self.window shakeWindow:^{
            [self.ftPassword2 becomeFirstResponder];
            [self.ftPassword2 selectText:self];
            self.ftFlavourText.stringValue = NSLocalizedString(@"The passwords don't match.", @"");
        }];
    } else {
        if (self.shouldUseKeychain) {
            [self savePasswordInKeychain:self.ftPassword1.stringValue forName:self.nameField.stringValue.strippedValue];
        }
        [NSApp endSheet:((NSView *)sender).window];
        [(SCAppDelegate *)[NSApp delegate] makeApplicationReadyForToxing:NULL
                                                                    name:self.nameField.stringValue
                                                                password:self.ftPassword1.stringValue];
    }
}

- (IBAction)changeKeychainUsage:(NSButton *)sender {
    self.shouldUseKeychain = sender.state == NSOnState? YES : NO;
    self.keychainCheck1.state = sender.state;
    self.keychainCheck2.state = sender.state;
}

- (void)failed:(NSString *)instruction {
    [self.window shakeWindow:^{
        [self.nameField becomeFirstResponder];
        [self.nameField selectText:self];
        if (instruction)
            self.instructionLabel.stringValue = instruction;
    }];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    if (!self.nameField.stringValue.isValidLoginName)
        self.instructionLabel.stringValue = NSLocalizedString(@"You can't leave the name blank.", @"");
    else
        self.instructionLabel.stringValue = SCLocalizedFormatString(@"Welcome to %@. Enter a nickname to get started.", nil, SCApplicationInfoDictKey(@"CFBundleName"));
    if ([SCProfileManager profileNameExists:self.nameField.stringValue.strippedValue])
        self.nextButton.title = NSLocalizedString(@"Log in", nil);
    else
        self.nextButton.title = NSLocalizedString(@"Next", nil);
}

- (BOOL)windowShouldClose:(id)sender {
    return YES;
}

#pragma mark - Sheets & alerts

- (IBAction)sheetCancel:(id)sender {
    [NSApp endSheet:((NSView *)sender).window];
    [self failed:SCLocalizedFormatString(@"Welcome to %@. Enter a nickname to get started.", nil, SCApplicationInfoDictKey(@"CFBundleName"))];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (contextInfo == SCAlertEndingShowPassword) {
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [NSApp beginSheet:self.passwordSheetUnlock modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
        });
    }
}


@end
