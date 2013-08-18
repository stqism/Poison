#import "SCChatViewController.h"
#import "SCChatView.h"
#import "SCBorderedGradientView.h"
#import "SCWebKitMessage.h"
#import "SCThemeManager.h"
#import <WebKit/WebKit.h>
#import <DeepEnd/DeepEnd.h>

@implementation SCChatViewController {
    NSFont *cachedFont;
}

- (void)awakeFromNib {
    cachedFont = [NSFont systemFontOfSize:13];
    self.headerView.topColor = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];;
    self.headerView.bottomColor = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
    self.headerView.borderColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    self.headerView.shadowColor = [NSColor whiteColor];
    self.headerView.dragsWindow = YES;
    self.messageInput.stringValue = @"";
    self.messageInput.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutViews:) name:NSViewFrameDidChangeNotification object:self.messageInput];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutViews:) name:NSViewFrameDidChangeNotification object:self.view];
    [self layoutViews:nil];
    SCThemeManager *manager = [SCThemeManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTheme:) name:SCTranscriptThemeDidChangeNotification object:manager];
    self.transcriptView.drawsBackground = NO;
    self.transcriptView.frameLoadDelegate = self;
    [self reloadTheme:nil];
}

- (void)setContext:(id<DESChatContext>)context {
    if (context == _context)
        return;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DESDidPushMessageToContextNotification object:_context];
    for (DESFriend *i in _context.participants) {
        [i removeObserver:self forKeyPath:@"displayName"];
    }
    _context = context;
    if (context) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messagePushed:) name:DESDidPushMessageToContextNotification object:context];
        [self setTitleUsingContext:context];
        [self.transcriptView reload:self];
        [self injectConstants];
        SCWebKitMessage *wm = [[SCWebKitMessage alloc] initWithMessage:nil];
        for (DESMessage *i in context.backlog) {
            wm.wrappedMessage = i;
            [[self.transcriptView.mainFrame windowObject] callWebScriptMethod:@"pushMessage" withArguments:@[i]];
        }
    }
    NSLog(@"Context changed");
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    [self injectConstants];
    [self.transcriptView.windowScriptObject setValue:self.context forKey:@"Conversation"];
}

- (void)injectConstants {
    /* This exports all DES constants to the webview. */
    WebScriptObject *w = self.transcriptView.windowScriptObject;
    [w setValue:[NSNumber numberWithInteger:DESFriendSelf] forKey:@"DESFriendSelf"];
    [w setValue:[NSNumber numberWithInteger:DESFriendInvalid] forKey:@"DESFriendInvalid"];
    
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusOffline] forKey:@"DESFriendStatusOffline"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusOnline] forKey:@"DESFriendStatusOnline"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusRequestReceived] forKey:@"DESFriendStatusRequestReceived"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusRequestSent] forKey:@"DESFriendStatusRequestSent"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusConfirmed] forKey:@"DESFriendStatusConfirmed"];
    [w setValue:[NSNumber numberWithInteger:DESFriendStatusSelf] forKey:@"DESFriendStatusSelf"];
    
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeOnline] forKey:@"DESStatusTypeOnline"];
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeAway] forKey:@"DESStatusTypeAway"];
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeBusy] forKey:@"DESStatusTypeBusy"];
    [w setValue:[NSNumber numberWithInteger:DESStatusTypeInvalid] forKey:@"DESStatusTypeInvalid"];
    
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeChat] forKey:@"DESMessageTypeChat"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeAction] forKey:@"DESMessageTypeAction"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeNicknameChange] forKey:@"DESMessageTypeNicknameChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeStatusChange] forKey:@"DESMessageTypeStatusChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeUserStatusChange] forKey:@"DESMessageTypeUserStatusChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeStatusTypeChange] forKey:@"DESMessageTypeStatusTypeChange"];
    [w setValue:[NSNumber numberWithInteger:DESMessageTypeSystem] forKey:@"DESMessageTypeSystem"];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    [self layoutViews:nil];
}

- (void)layoutViews:(NSNotification *)notification {
    NSRect sz = [self.messageInput.stringValue boundingRectWithSize:(NSSize){self.messageInput.bounds.size.width - 10, self.view.bounds.size.height / 2} options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingDisableScreenFontSubstitution attributes:@{NSFontAttributeName: cachedFont}];
    if (sz.size.height != self.messageInput.bounds.size.height) {
        [self.messageInput setFrameSize:(NSSize){self.messageInput.bounds.size.width, MAX(22, MIN(sz.size.height + 5, self.view.frame.size.height / 2))}];
    }
    [self.view.window setContentBorderThickness:self.messageInput.frame.size.height + 19 forEdge:NSMinYEdge];
    CGFloat transcriptYOffset = self.messageInput.frame.size.height + 19;
    self.transcriptView.frame = (NSRect){{0, transcriptYOffset}, {self.view.frame.size.width, self.view.frame.size.height - (self.headerView.frame.size.height + transcriptYOffset)}};
    self.view.needsDisplay = YES;
}

- (void)reloadTheme:(NSNotification *)notification {
    SCThemeManager *manager = [SCThemeManager sharedManager];
    ((SCChatView*)self.view).topColor = [manager backgroundColorOfCurrentTheme];
    NSURLRequest *request = [NSURLRequest requestWithURL:[manager baseTemplateURLOfCurrentTheme]];
    [self.transcriptView.mainFrame loadRequest:request];
}

- (void)messagePushed:(NSNotification *)notification {
    DESMessage *message = notification.userInfo[@"message"];
    [[self.transcriptView.mainFrame windowObject] callWebScriptMethod:@"pushMessage" withArguments:@[[[SCWebKitMessage alloc] initWithMessage:message]]];
}

- (IBAction)submitMessage:(id)sender {
    NSString *payload = [self.messageInput.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([payload isEqualToString:@""]) {
        self.messageInput.stringValue = @"";
        [self layoutViews:nil];
        return;
    }
    [self.context sendMessage:payload];
    self.messageInput.stringValue = @"";
    [self layoutViews:nil];
}

- (void)setTitleUsingContext:(id<DESChatContext>)context {
    NSMutableArray *names = [[NSMutableArray alloc] initWithCapacity:[context.participants count]];
    for (DESFriend *i in [context.participants sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]]) {
        [names addObject:i.displayName];
        [i addObserver:self forKeyPath:@"displayName" options:NSKeyValueObservingOptionNew context:NULL];
    }
    self.partnerName.stringValue = [names componentsJoinedByString:@", "];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"displayName"]) {
        [self setTitleUsingContext:_context];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_context) {
        for (DESFriend *i in _context.participants) {
            [i removeObserver:self forKeyPath:@"displayName"];
        }
    }
}

@end
