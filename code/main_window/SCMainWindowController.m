#import "SCMainWindowController.h"
#import "SCShinyWindow.h"
#import "SCDHTStatusView.h"
#import "SCGradientView.h"
#import "PXListView.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD) {
        /* To eliminate IB warning, set fullscreen capability in code. */
        self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    }
    self.window.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restrainSplitter:) name:NSWindowDidResizeNotification object:self.window];
    [(SCShinyWindow*)self.window repositionDHT];
    self.sidebarHead.topColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    self.sidebarHead.bottomColor = [NSColor colorWithCalibratedWhite:0.09 alpha:1.0];
    self.sidebarHead.shadowColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.sidebarHead.dragsWindow = YES;
    self.sidebarHead.needsDisplay = YES;
    [self.displayName.cell setTextColor:[NSColor whiteColor]];
    [self.userStatus.cell setTextColor:[NSColor controlColor]];
    self.userImage.layer.cornerRadius = 2.0;
    self.userImage.layer.masksToBounds = YES;
    if (OS_VERSION_IS_BETTER_THAN_SNOW_LEOPARD)
        self.listView.scrollerKnobStyle = NSScrollerKnobStyleLight; /* Set in code to avoid IB warning. */
    [[DESSelf self] addObserver:self forKeyPath:@"userStatus" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESSelf self] addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESSelf self] addObserver:self forKeyPath:@"userStatusKind" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESToxNetworkConnection sharedConnection] addObserver:self forKeyPath:@"connectedNodeCount" options:NSKeyValueObservingOptionNew context:NULL];
    ((SCShinyWindow*)self.window).indicator.connectedNodes = [[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [DESSelf self]) {
        if ([keyPath isEqualToString:@"userStatus"]) {
            self.userStatus.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"displayName"]) {
            self.displayName.stringValue = change[NSKeyValueChangeNewKey];
        }
    } else if (object == [DESToxNetworkConnection sharedConnection]) {
        ((SCShinyWindow*)self.window).indicator.connectedNodes = [change[NSKeyValueChangeNewKey] integerValue];
    }
}

- (IBAction)statusLabelAction:(NSTextField *)sender {
    sender.editable = NO;
    sender.backgroundColor = [NSColor clearColor];
    if (sender == self.displayName)
        sender.textColor = [NSColor whiteColor];
    else
        sender.textColor = [NSColor controlColor];
    sender.drawsBackground = NO;
    
    if (![[DESToxNetworkConnection sharedConnection].me.displayName isEqualToString:self.displayName.stringValue]) {
        [DESToxNetworkConnection sharedConnection].me.displayName = [self.displayName.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if (![[DESToxNetworkConnection sharedConnection].me.userStatus isEqualToString:self.userStatus.stringValue]) {
        [DESToxNetworkConnection sharedConnection].me.userStatus = [self.userStatus.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

- (IBAction)quickChangeStatus:(NSMenuItem *)sender {
    switch (sender.tag) {
        case 0:
            [DESToxNetworkConnection sharedConnection].me.userStatus = @"Online";
            break;
        case 1:
            [DESToxNetworkConnection sharedConnection].me.userStatus = @"Away";
            break;
        case 2:
            [DESToxNetworkConnection sharedConnection].me.userStatus = @"Busy";
            break;
        default:
            break;
    }
}

- (void)dealloc {
    [[DESSelf self] removeObserver:self forKeyPath:@"userStatus"];
    [[DESSelf self] removeObserver:self forKeyPath:@"displayName"];
    [[DESSelf self] removeObserver:self forKeyPath:@"statusType"];
}

#pragma mark - Sheets

- (IBAction)presentCustomStatusSheet:(id)sender {
    self.statusSheetField.stringValue = [DESToxNetworkConnection sharedConnection].me.userStatus;
    [NSApp beginSheet:self.statusChangeSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)presentNickChangeSheet:(id)sender {
    self.nickSheetField.stringValue = [DESToxNetworkConnection sharedConnection].me.displayName;
    [NSApp beginSheet:self.nickChangeSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)confirmAndEndSheet:(NSButton *)sender {
    [NSApp endSheet:self.window.attachedSheet returnCode:sender.tag];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *proposed = nil;
    [sheet orderOut:self];
    switch (returnCode) {
        case 1: /* Nickname was changed. */
            proposed = [self.nickSheetField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (![[DESToxNetworkConnection sharedConnection].me.displayName isEqualToString:proposed]) {
                [DESToxNetworkConnection sharedConnection].me.displayName = proposed;
            }
            break;
        case 2:
            proposed = [self.statusSheetField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (![[DESToxNetworkConnection sharedConnection].me.userStatus isEqualToString:proposed]) {
                [DESToxNetworkConnection sharedConnection].me.userStatus = proposed;
            }
            break;
        default:
            break;
    }
}

#pragma mark - NSWindow delegate

- (void)restrainSplitter:(NSNotification *)notification {
    CGFloat originalPosition = ((NSView*)[self.splitView subviews][0]).frame.size.width;
    self.splitView.frame = ((NSView*)self.window.contentView).frame;
    [self.splitView setPosition:originalPosition ofDividerAtIndex:0];
}

- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window {
    ((SCShinyWindow*)self.window).indicator.hidden = YES;
    return nil;
}

- (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window {
    ((SCShinyWindow*)self.window).indicator.hidden = NO;
    return nil;
}

- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
    ((SCShinyWindow*)self.window).indicator.hidden = NO;
}

#pragma mark - NSSplitView delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedPosition < 150) {
        return 150;
    } else if (proposedPosition > 300) {
        return 300;
    } else {
        return proposedPosition;
    }
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

@end
