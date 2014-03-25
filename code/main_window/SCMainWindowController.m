#include "Copyright.h"

#import "SCMainWindowController.h"
#import "NSString+CanonicalID.h"
#import "NSURL+Parameters.h"
#import "ObjectiveTox.h"

@interface SCMainWindowController ()
@property (weak) DESToxConnection *tox;
@end

@implementation SCMainWindowController

- (instancetype)initWithDESConnection:(DESToxConnection *)tox {
    self = [super init];
    if (self) {
        self.tox = tox;
    }
    return self;
}

#pragma mark - sheets

- (void)displayQRCode {
    if (!self.qrPanel)
        self.qrPanel = [[SCQRCodeSheetController alloc] initWithWindowNibName:@"QRSheet"];
    self.qrPanel.friendAddress = self.tox.friendAddress;
    self.qrPanel.name = self.tox.name;
    [NSApp beginSheet:self.qrPanel.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)displayAddFriend {
    if (!self.addPanel)
        self.addPanel = [[SCAddFriendSheetController alloc] initWithWindowNibName:@"AddFriend"];
    [self.addPanel resetFields];
    [self.addPanel loadWindow];
    NSArray *objects = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSString class]] options:nil];
    for (NSString *item in objects) {
        NSString *canonical = item.canonicalToxID;
        if (canonical) {
            self.addPanel.toxID = canonical;
            break;
        }
        if ([item rangeOfString:@"tox://"].location == 0) {
            [self displayAddFriendWithToxSchemeURL:[NSURL URLWithString:item]];
            return;
        }
    }
    [NSApp beginSheet:self.addPanel.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)displayAddFriendWithToxSchemeURL:(NSURL *)url {
    if (!self.addPanel)
        self.addPanel = [[SCAddFriendSheetController alloc] initWithWindowNibName:@"AddFriend"];
    [self.addPanel resetFields];
    [self.addPanel loadWindow];
    /* +1 accounts for the third slash. */
    if (url.path.length != (DESFriendAddressSize * 2) + 1 && url.host.length != DESFriendAddressSize * 2) {
        NSAlert *error = [[NSAlert alloc] init];
        error.alertStyle = NSInformationalAlertStyle;
        error.messageText = NSLocalizedString(@"Invalid Tox ID.", nil);
        error.informativeText = NSLocalizedString(@"That Tox URL doesn't look right. Are you sure that it's correct?", nil);
        [error addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)];
        [error beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        return;
    }
    self.addPanel.toxID = ([url.path substringFromIndex:1] ?: url.host);
    if (url.query) {
        NSDictionary *params = url.parameters;
        if ([params[@"message"] isKindOfClass:[NSString class]]) {
            [self.addPanel setMessage:params[@"message"]];
        }
    }
    [NSApp beginSheet:self.addPanel.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

@end
