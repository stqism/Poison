// You will not find the licensing jibber-jabber here.
// Go read it elsewhere.

#import "SCPreferencesWindowController.h"

@implementation SCPreferencesWindowController {
    NSViewController *currentPane;
    NSString *previousSelectedItemIdentifier;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    for (NSToolbarItem *toolbarItem in [self.toolbar items]) {
        toolbarItem.target = self;
        toolbarItem.action = @selector(didChangeSettingsPane:);
    }
    previousSelectedItemIdentifier = @"";
    self.toolbar.selectedItemIdentifier = @"GeneralPane";
    [self didChangeSettingsPane:self.toolbar.items[0]];
}

- (IBAction)didChangeSettingsPane:(NSToolbarItem *)sender {
    NSString *nibToLoad = sender.itemIdentifier;
    if ([nibToLoad isEqualToString:previousSelectedItemIdentifier]) return;
    CGFloat chromeHeight = self.window.frame.size.height - ((NSView*)self.window.contentView).bounds.size.height;
    NSNib *theNib = [[NSNib alloc] initWithNibNamed:nibToLoad bundle:[NSBundle mainBundle]];
    NSArray *objects = nil;
    BOOL success = NO;
    if (OS_VERSION_IS_BETTER_THAN_LION) {
        success = [theNib instantiateWithOwner:self topLevelObjects:&objects];
    } else {
        success = [theNib instantiateNibWithOwner:self topLevelObjects:&objects];
    }
    if (success && [objects count] > 0) {
        for (id theView in objects) {
            if ([theView isKindOfClass:[NSViewController class]]) {
                currentPane = (NSViewController*)theView;
                break;
            }
        }
        [self.window.contentView setHidden:YES];
        [self.window setFrame:(NSRect){{self.window.frame.origin.x, self.window.frame.origin.y - (currentPane.view.frame.size.height + chromeHeight - self.window.frame.size.height)}, {currentPane.view.frame.size.width, currentPane.view.frame.size.height + chromeHeight}} display:YES animate:YES];
        [self.window setContentView:currentPane.view];
        [self.window.contentView setHidden:NO];
    }
}

@end
