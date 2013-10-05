#import "SCAlertsPaneController.h"
#import "SCSoundManager.h"
#import "SCNotificationManager.h"
#import <objc/runtime.h>

@implementation SCAlertsPaneController {
    NSMutableArray *paths;
    NSMutableDictionary *info;
}

- (void)awakeFromNib {
    [self refreshMenu];
    [self updateInfoBox];
    if (![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"alertVolume"]) {
        [[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"alertVolume"];
    }
    self.alertVolume.integerValue = (NSInteger)([[NSUserDefaults standardUserDefaults] floatForKey:@"alertVolume"] * 100.0);
}

- (void)refreshMenu {
    SCSoundManager *manager = [SCSoundManager sharedManager];
    paths = [[manager availableSoundSets] mutableCopy];
    info = [[NSMutableDictionary alloc] initWithCapacity:[paths count]];
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *selected = nil;
    for (NSString *path in paths) {
        info[path] = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"soundset.plist"]];
        NSString *title = info[path][@"aiThemeHumanReadableName"];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title ? title : @"" action:NULL keyEquivalent:@""];
        if ([path isEqualToString:manager.pathOfCurrentSoundSetDirectory]) {
            selected = item;
        }
        [menu addItem:item];
    }
    self.soundSelection.menu = menu;
    [self.soundSelection selectItem:selected];
}

- (void)updateInfoBox {
    if (self.soundSelection.indexOfSelectedItem == -1) {
        return;
    }
    NSDictionary *selectedInfo = info[paths[self.soundSelection.indexOfSelectedItem]];
    NSString *name = selectedInfo[@"aiThemeHumanReadableName"];
    if (!name)
        name = NSLocalizedString(@"Untitled", @"");
    NSString *author = selectedInfo[@"aiThemeAuthor"];
    if (!author)
        author = NSLocalizedString(@"(unknown)", @"");
    NSString *description = selectedInfo[@"aiThemeDescription"];
    if (!description)
        description = NSLocalizedString(@"No description provided.", @"");
    self.soundSetName.stringValue = name;
    self.soundSetAuthor.stringValue = [NSString stringWithFormat:NSLocalizedString(@"by %@", @""), author];
    self.soundSetDescription.stringValue = description;
    if ([[SCSoundManager sharedManager] currentSoundSetIsSystemProvided]) {
        self.builtInInfoLabel.hidden = NO;
        self.uninstallButton.hidden = YES;
        self.revealButton.hidden = YES;
    } else {
        self.builtInInfoLabel.hidden = YES;
        self.uninstallButton.hidden = NO;
        self.revealButton.hidden = NO;
    }
}

- (IBAction)revealSelectedSoundSet:(id)sender {
    NSString *path = paths[self.soundSelection.indexOfSelectedItem];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
}

- (IBAction)changeSoundSet:(id)sender {
    SCSoundManager *manager = [SCSoundManager sharedManager];
    [manager changeSoundSetPath:paths[self.soundSelection.indexOfSelectedItem]];
    [self updateInfoBox];
    [[NSUserDefaults standardUserDefaults] setObject:paths[self.soundSelection.indexOfSelectedItem] forKey:@"hiSetDirectory"];
}

- (IBAction)deleteSelectedSet:(id)sender {
    NSDictionary *selectedInfo = info[paths[self.soundSelection.indexOfSelectedItem]];
    NSString *name = selectedInfo[@"aiThemeHumanReadableName"];
    if (!name)
        name = NSLocalizedString(@"Untitled", @"");
    NSAlert *confirm = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete the sound set \"%@\"?", @""), name] defaultButton:NSLocalizedString(@"Delete", @"") alternateButton:NSLocalizedString(@"Cancel", @"") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone.", @"")];
    [confirm beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(didConfirmDelete:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)didConfirmDelete:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSError *err = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm removeItemAtPath:[SCSoundManager sharedManager].pathOfCurrentSoundSetDirectory error:&err]) {
            NSAlert *failAlert = [NSAlert alertWithError:err];
            [failAlert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        } else {
            [[SCSoundManager sharedManager] changeSoundSetPath:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"psnSounds" inDirectory:@"SoundSets"]];
            [self refreshMenu];
            [self.soundSelection selectItemAtIndex:0];
            [self changeSoundSet:self];
            [self updateInfoBox];
        }
    }
}

- (IBAction)changeVolume:(id)sender {
    NSLog(@"%lu", (long)[self.alertVolume integerValue]);
    [[NSUserDefaults standardUserDefaults] setFloat:(float)[self.alertVolume integerValue] / 100.0f forKey:@"alertVolume"];
}

- (IBAction)playSound:(id)sender {
    if (![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"alertVolume"]) {
        [[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"alertVolume"];
    }
    NSSound *sound = [[SCSoundManager sharedManager] soundForEventType:self.eventTypePicker.selectedTag];
    if (sound) {
        [sound play];
    }
}

@end
