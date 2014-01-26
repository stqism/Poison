//
//  SCAppDelegate.h
//  Inspectox
//
//  Created by stal on 25/1/2014.
//  Copyright (c) 2014 Zodiac Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SCAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *addressField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *keyField;

@property (weak) IBOutlet NSButton *connectButton;
@property (weak) IBOutlet NSButton *clearButton;
@property (weak) IBOutlet NSButton *discardButton;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *DEVersionLabel;
@property (weak) IBOutlet NSTextField *myPub;
@property (weak) IBOutlet NSTextField *myPriv;

@property (weak) IBOutlet NSTableColumn *addressColumn;
@property (weak) IBOutlet NSTableColumn *idColumn;
@property (weak) IBOutlet NSTableColumn *timestampColumn;

@end
