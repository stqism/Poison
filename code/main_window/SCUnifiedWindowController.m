#include "Copyright.h"

#import <qrencode.h>
#import "SCUnifiedWindowController.h"
#import "SCBuddyListController.h"
#import "SCChatViewController.h"
#import "CGGeometryExtreme.h"
#import "SCQRCodeSheetController.h"
#import "ObjectiveTox.h"
#import "NSURL+Parameters.h"
#import "NSString+CanonicalID.h"

#define SCUnifiedDefaultWindowFrame ((CGRect){{0, 0}, {800, 400}})
#define SCUnifiedMinimumSize ((CGSize){800, 400})

@interface SCUnifiedWindowController ()
@property (weak) SCNonGarbageSplitView *rootView;
@property (strong) SCBuddyListController *friendsListCont;
@property (strong) SCChatViewController *chatViewCont;
@property (weak) DESToxConnection *tox;
@property CGRect savedFrame;
@end

@implementation SCUnifiedWindowController

- (instancetype)initWithDESConnection:(DESToxConnection *)tox {
    self = [super initWithDESConnection:tox];
    if (self) {
        NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectCentreInRect(SCUnifiedDefaultWindowFrame, [NSScreen mainScreen].visibleFrame) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES];
        window.restorable = NO;
        window.minSize = SCUnifiedMinimumSize;
        [window setFrameUsingName:@"UnifiedWindow"];
        window.frameAutosaveName = @"UnifiedWindow";
        window.title = SCApplicationInfoDictKey(@"CFBundleName");
        window.delegate = self;
        self.window = window;
        self.tox = tox;
        [self prepareSplit];
    }
    return self;
}

- (void)prepareSplit {
    SCNonGarbageSplitView *root = [[SCNonGarbageSplitView alloc] initWithFrame:((NSView*)self.window.contentView).frame];
    root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    root.vertical = YES;
    root.frame = ((NSView*)self.window.contentView).frame;
    root.delegate = self;
    [root setDividerStyle:NSSplitViewDividerStyleThin];
    
    self.friendsListCont = [[SCBuddyListController alloc] initWithNibName:@"FriendsPanel" bundle:[NSBundle mainBundle]];
    [self.friendsListCont loadView];
    [self.friendsListCont attachKVOHandlersToConnection:self.tox];
    [root addSubview:self.friendsListCont.view];
    
    self.chatViewCont = [[SCChatViewController alloc] initWithNibName:@"ChatPanel" bundle:[NSBundle mainBundle]];
    [self.chatViewCont loadView];
    self.chatViewCont.showsVideoPane = NO;
    self.chatViewCont.showsUserList = NO;
    [root addSubview:self.chatViewCont.view];
    [root adjustSubviews];
    [root setPosition:220 ofDividerAtIndex:0];
    
    self.rootView = root;
    [self.window.contentView addSubview:self.rootView];
    [root setAutosaveName:@"UnifiedSplitPane"];
}

#pragma mark - Split view delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 220;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 400;
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    CGSize deltas = (CGSize){splitView.frame.size.width - oldSize.width, splitView.frame.size.height - oldSize.height};
    NSView *expands = (NSView*)splitView.subviews[1];
    NSView *doesntExpand = (NSView*)splitView.subviews[0];
    expands.frame = (CGRect){{doesntExpand.frame.size.width + 1, 0}, {expands.frame.size.width + deltas.width, expands.frame.size.height + deltas.height}};
    doesntExpand.frameSize = (CGSize){splitView.frame.size.width - expands.frame.size.width - 1, splitView.frame.size.height};
}

- (NSColor *)dividerColourForSplitView:(SCNonGarbageSplitView *)splitView {
    return [NSColor controlDarkShadowColor];
}

#pragma mark - Window delegate

/*- (void)windowDidResize:(NSNotification *)notification {
    if (self.savedFrame.size.width == ((NSWindow*)notification.object).frame.size.width) {
        return;
    } else {
        CGFloat originalPosition = _friendsListCont.view.frame.size.width;
        [self.rootView setFrameSize:((NSView*)self.window.contentView).frame.size];
        [self.rootView setPosition:originalPosition ofDividerAtIndex:0];
    }
}*/

@end
