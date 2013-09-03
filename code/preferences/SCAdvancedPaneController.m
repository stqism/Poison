#import "SCAdvancedPaneController.h"

@implementation SCAdvancedPaneController

- (IBAction)emptyNodeCache:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths[0] stringByAppendingPathComponent:@"Poison"];
    NSError *err = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[basePath stringByAppendingPathComponent:@"Nodefile"] error:&err];
    if (err) {
        NSAlert *alert = [NSAlert alertWithError:err];
        [alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Operation complete", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The cache was removed successfully.", @"")];
        [alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    }
}

- (IBAction)emptyThemeFolder:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths[0] stringByAppendingPathComponent:@"Poison"];
    NSError *err = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[basePath stringByAppendingPathComponent:@"Themes"] error:&err];
    if (err) {
        NSAlert *alert = [NSAlert alertWithError:err];
        [alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Operation complete", @"") defaultButton:NSLocalizedString(@"OK", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The theme folder was deleted.", @"")];
        [alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    }
}

@end
