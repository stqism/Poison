#import "SCConnectionContext.h"
#import "SCMainWindowController.h"
#import <DeepEnd/DeepEnd.h>

@implementation SCConnectionContext

- (instancetype)initWithConnection:(DESToxNetworkConnection *)aConnection {
    self = [super init];
    if (self) {
        _connection = aConnection;
        _mainWindow = [[SCMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
        _mainWindow.context = self;
        _standaloneWindows = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (NSString *)name {
    return _connection.me.displayName;
}

- (void)dealloc {
    _mainWindow = nil;
}

@end
