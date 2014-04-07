#include "Copyright.h"

#import "SCEditingField.h"

@implementation SCEditingField {
    NSAttributedString *_shadowedStringValue;
    NSTrackingArea *_trackingArea;
    BOOL _trackingAreaUpdateDisabled;
}

- (void)updateTrackingAreas {
    if (_trackingAreaUpdateDisabled)
        return;

    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }

    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                   owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)viewWillStartLiveResize {
    _trackingAreaUpdateDisabled = YES;
}

- (void)viewDidEndLiveResize {
    _trackingAreaUpdateDisabled = NO;
    [self updateTrackingAreas];
}

- (void)setStringValue:(NSString *)aString {
    [super setStringValue:aString];
    _shadowedStringValue = [[NSAttributedString alloc] initWithString:aString];
}

- (void)setAttributedStringValue:(NSAttributedString *)obj {
    [super setAttributedStringValue:obj];
    _shadowedStringValue = [obj copy];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc]
                                    initWithString:NSLocalizedString(@"\u270E ", @"The space is important!")
                                    attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:11],
                                                 NSForegroundColorAttributeName: [NSColor disabledControlTextColor]}];
    [s appendAttributedString:_shadowedStringValue];
    [super setAttributedStringValue:s];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super setAttributedStringValue:_shadowedStringValue];
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (self.action)
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:self];
        #pragma clang diagnostic pop
}

@end
