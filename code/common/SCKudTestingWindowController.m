#import "SCKudTestingWindowController.h"
#import <Kudryavka/Kudryavka.h>
#import <Kudryavka/NKToxDataWriter.h>

@implementation SCKudTestingWindowController

- (IBAction)trySaveData:(id)sender {
    NKToxDataWriter *writer = [[NKToxDataWriter alloc] initWithConnection:[DESToxNetworkConnection sharedConnection]];
    uint8_t *buf = nil;
    size_t buflen = 0;
    NSDate *start = [NSDate date];
    [writer encodeDataIntoBuffer:&buf outputLength:&buflen];
    NSTimeInterval end = [[NSDate date] timeIntervalSinceDate:start];
    self.timeField.stringValue = [NSString stringWithFormat:@"%f", end];
    self.lengthField.stringValue = [NSString stringWithFormat:@"%zu", buflen];
    [[NSData dataWithBytes:buf length:buflen] writeToFile:@"/Volumes/stal/data" atomically:YES];
}

@end
