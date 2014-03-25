#include "Copyright.h"

#import "SCBuddyListWindowController.h"
#import "SCBuddyListController.h"
#import "DESToxConnection.h"
#import "CGGeometryExtreme.h"

#define SCBuddyListDefaultWindowFrame ((CGRect){{0, 0}, {290, 400}})
#define SCBuddyListMinimumSize ((CGSize){290, 142})

@interface SCBuddyListWindowController ()
@property (strong) SCBuddyListController *friendsListCont;
@property (weak) DESToxConnection *tox;
@end

@implementation SCBuddyListWindowController

- (instancetype)initWithDESConnection:(DESToxConnection *)tox {
    self = [super initWithDESConnection:tox];
    if (self) {
        NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectCentreInRect(SCBuddyListDefaultWindowFrame, [NSScreen mainScreen].visibleFrame) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES];
        window.restorable = NO;
        window.minSize = SCBuddyListMinimumSize;
        [window setFrameUsingName:@"MainWindow"];
        window.frameAutosaveName = @"MainWindow";
        window.title = [NSString stringWithFormat:NSLocalizedString(@"%@ \u2014 Friends", @"friends list window title"), SCApplicationInfoDictKey(@"CFBundleName")];
        self.window = window;
        self.tox = tox;
        self.friendsListCont = [[SCBuddyListController alloc] initWithNibName:@"FriendsPanel" bundle:[NSBundle mainBundle]];
        [self.friendsListCont attachKVOHandlersToConnection:tox];
        [self.friendsListCont loadView];
        self.friendsListCont.view.frame = ((NSView*)window.contentView).frame;
        self.window.contentView = self.friendsListCont.view;
    }
    return self;
}

@end
