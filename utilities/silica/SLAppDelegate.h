#import <Cocoa/Cocoa.h>

@class WebView, SLBackingView;
@interface SLAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet SLBackingView *backing;
@property (unsafe_unretained) IBOutlet WebView *webView;

@end
