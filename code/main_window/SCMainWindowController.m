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
    [[DESSelf self] addObserver:self forKeyPath:@"statusType" options:NSKeyValueObservingOptionNew context:NULL];
    [[DESToxNetworkConnection sharedConnection] addObserver:self forKeyPath:@"connectedNodeCount" options:NSKeyValueObservingOptionNew context:NULL];
    ((SCShinyWindow*)self.window).indicator.connectedNodes = [[DESToxNetworkConnection sharedConnection].connectedNodeCount integerValue];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [DESSelf self]) {
        if ([keyPath isEqualToString:@"userStatus"]) {
            self.userStatus.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"displayName"]) {
            self.displayName.stringValue = change[NSKeyValueChangeNewKey];
        } else if ([keyPath isEqualToString:@"statusType"]) {
            switch ([DESSelf self].statusType) {
                case DESStatusTypeAway:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-away"];
                    break;
                case DESStatusTypeBusy:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-offline"];
                    break;
                default:
                    self.statusLight.image = [NSImage imageNamed:@"status-light-online"];
                    break;
            }
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
            [[DESToxNetworkConnection sharedConnection].me setUserStatus:@"Online" kind:DESStatusTypeOnline];
            break;
        case 1:
            [[DESToxNetworkConnection sharedConnection].me setUserStatus:@"Away" kind:DESStatusTypeAway];
            break;
        case 2:
            [[DESToxNetworkConnection sharedConnection].me setUserStatus:@"Busy" kind:DESStatusTypeBusy];
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
    switch ([DESSelf self].statusType) {
        case DESStatusTypeAway:
            [self.statusSheetPopUp selectItemWithTag:2];
            break;
        case DESStatusTypeBusy:
            [self.statusSheetPopUp selectItemWithTag:3];
            break;
        default:
            [self.statusSheetPopUp selectItemWithTag:1];
            break;
    }
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
            if ([proposed isEqualToString:@""]) return;
            if (![[DESToxNetworkConnection sharedConnection].me.displayName isEqualToString:proposed]) {
                [DESToxNetworkConnection sharedConnection].me.displayName = proposed;
            }
            break;
        case 2: {
            proposed = [self.statusSheetField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([proposed isEqualToString:@""]) return;
            DESStatusType kind = DESStatusTypeRetain;
            switch([self.statusSheetPopUp.selectedItem tag]) {
                case 1:
                    kind = DESStatusTypeOnline; break;
                case 2:
                    kind = DESStatusTypeAway; break;
                case 3:
                    kind = DESStatusTypeBusy; break;
                default:
                    break;
            }
            DESFriend *me = [DESSelf self];
            if ((![me.userStatus isEqualToString:proposed]) || me.statusType != kind) {
                [(DESSelf*)me setUserStatus:proposed kind:kind];
            }
            break;
        }
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
