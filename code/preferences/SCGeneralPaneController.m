#import "SCGeneralPaneController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCGeneralPaneController

- (void)awakeFromNib {
    NSInteger speed = [[NSUserDefaults standardUserDefaults] integerForKey:@"DESRunLoopSpeed"];
    if (!speed) {
        speed = (NSInteger)(1 / DEFAULT_MESSENGER_TICK_RATE);
        [[NSUserDefaults standardUserDefaults] setInteger:speed forKey:@"DESRunLoopSpeed"];
    }
    switch (speed) {
        case 200:
            self.radioButton200.state = NSOnState;
            break;
        case 100:
            self.radioButton100.state = NSOnState;
            break;
        case 20:
            self.radioButton20.state = NSOnState;
            break;
        case 10:
            self.radioButton10.state = NSOnState;
            break;
        default:
            break;
    }
}

- (IBAction)runLoopSpeedChanged:(NSButton *)sender {
    self.radioButton10.state = NSOffState;
    self.radioButton20.state = NSOffState;
    self.radioButton100.state = NSOffState;
    self.radioButton200.state = NSOffState;
    sender.state = NSOnState;
    NSLog(@"%li", (long)sender.tag);
    [[NSUserDefaults standardUserDefaults] setInteger:sender.tag forKey:@"DESRunLoopSpeed"];
    [DESToxNetworkConnection sharedConnection].runLoopSpeed = (1.0 / (double)sender.tag);
}

@end
