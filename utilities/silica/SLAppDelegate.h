#import <Cocoa/Cocoa.h>

@class WebView, SLBackingView, SCBorderedGradientView;
@interface SLAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet SLBackingView *backing;
@property (unsafe_unretained) IBOutlet WebView *webView;
@property (unsafe_unretained) IBOutlet SCBorderedGradientView *topBar;
@property (unsafe_unretained) IBOutlet NSTextField *topBarLabel;

@end
