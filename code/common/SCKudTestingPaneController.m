#import "SCKudTestingPaneController.h"
#import <Kudryavka/Kudryavka.h>
#import <DeepEnd/DeepEnd.h>

@implementation SCKudTestingPaneController

- (IBAction)trySaveData:(id)sender {
    NKDataSerializer *kud = [[NKDataSerializer alloc] init];
    NSDate *start = [NSDate date];
    NSData *arc = [kud archivedDataWithConnection:[DESToxNetworkConnection sharedConnection]];
    NSTimeInterval end = [[NSDate date] timeIntervalSinceDate:start];
    self.timeField.stringValue = [NSString stringWithFormat:@"%f", end];
    self.lengthField.stringValue = [NSString stringWithFormat:@"%zu", [arc length]];
    [arc writeToFile:[NSString stringWithFormat:@"%@/data", NSHomeDirectory()] atomically:YES];
}

@end
