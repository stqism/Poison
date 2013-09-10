#import <Foundation/Foundation.h>

@class SCMainWindowController, DESToxNetworkConnection;
@interface SCConnectionContext : NSObject

@property (strong) SCMainWindowController *mainWindow;
@property (strong) DESToxNetworkConnection *connection;
@property (strong) NSArray *standaloneWindows;
@property (readonly) NSString *name;

- (instancetype)initWithConnection:(DESToxNetworkConnection *)aConnection;

@end
