#ifndef CGGeometryExtreme_h
#define CGGeometryExtreme_h
#import <CoreGraphics/CGGeometry.h>

/**
 * Returns a copy of r1 centered in r2.
 */
static inline CGRect CGRectCentreInRect(CGRect r1, CGRect r2) {
    return (CGRect){{(r2.size.width - r1.size.width) / 2.0, (r2.size.height - r1.size.height) / 2.0}, r1.size};
}

#endif
