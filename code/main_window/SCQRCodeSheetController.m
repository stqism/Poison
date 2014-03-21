//
//  SCQRCodeSheetController.m
//  Poison
//
//  Created by stal on 6/3/2014.
//  Copyright (c) 2014 Project Tox. All rights reserved.
//

#import "SCQRCodeSheetController.h"
#import "ObjectiveTox.h"
#import <qrencode.h>

#define SCQRCodeBorderWidth (2)
#define SCQRCodeBlockSize   (6)

NS_INLINE void SCDrawQRRow(CGContextRef cgi, const uint8_t *data, uint32_t len, uint32_t y, CGRect *scratch) {
    uint32_t count = 0;
    for (int i = 0; i < len; i++) {
        if (data[i] & 1) { /* if block is black */
            //NSLog(@"i'm not racist, but the block at %d is black", i);
            scratch[count].origin.x = (SCQRCodeBorderWidth + i) * SCQRCodeBlockSize;
            scratch[count].origin.y = y;
            scratch[count].size.width = SCQRCodeBlockSize;
            scratch[count].size.height = SCQRCodeBlockSize;
            ++count;
        }
    }
    CGContextFillRects(cgi, scratch, count);
}

static CGImageRef SCCreateQRCodeImage(QRcode *code, CGFloat scale, CGSize *outSize) {
    CGFloat sz = (code->width + SCQRCodeBorderWidth * 2) * SCQRCodeBlockSize;
    if (outSize)
        *outSize = (CGSize){sz, sz};
    CGColorSpaceRef bw = CGColorSpaceCreateDeviceGray();
    CGContextRef dctx = CGBitmapContextCreate(NULL, sz, sz, 8, 0, bw, kCGBitmapByteOrderDefault | kCGImageAlphaNone);
    CGContextSetGrayFillColor(dctx, 1.0, 1.0);
    CGContextFillRect(dctx, (CGRect){0, 0, sz, sz});

    CGContextSetGrayFillColor(dctx, 0.0, 1.0);
    CGFloat y = SCQRCodeBorderWidth * SCQRCodeBlockSize;
    CGRect *scratch = calloc(sizeof(CGRect), code->width);
    for (int row = code->width - 1; row >= 0; --row) {
        SCDrawQRRow(dctx, code->data + (code->width * row), code->width, y, scratch);
        y += SCQRCodeBlockSize;
    }
    free(scratch);

    CGImageRef img = CGBitmapContextCreateImage(dctx);
    CGContextRelease(dctx);
    CGColorSpaceRelease(bw);
    return img;
}

@interface SCQRCodeSheetController ()
@property (strong) IBOutlet NSImageView *codeView;
@property (strong) IBOutlet NSTextField *nameView;
@property (strong) IBOutlet NSTextField *guideView;
@end

@implementation SCQRCodeSheetController

- (void)setFriendAddress:(NSString *)friendAddress {
    if ([friendAddress length] != DESFriendAddressSize * 2)
        return;
    NSString *toxURL = [NSString stringWithFormat:@"tox:///%@", friendAddress];
    [self loadWindow];
    QRcode *code = QRcode_encodeString([toxURL UTF8String], 5, QR_ECLEVEL_M, QR_MODE_8, 1);
    CGSize size = (CGSize){0, 0};
    /* TODO: figure out a way to detect the scale of the screen
     * we will be showing this on, and adjust scale to match 
     * Displaying 2x image for all cases works okay right now */
    CGImageRef raw = SCCreateQRCodeImage(code, 2.0, &size);
    self.codeView.image = [[NSImage alloc] initWithCGImage:raw size:size];
    CGImageRelease(raw);
    _friendAddress = friendAddress;
}

- (void)setName:(NSString *)name {
    NSWindow *sheet = self.nameView.window;
    CGFloat nominalH = sheet.frame.size.height - self.nameView.frame.size.height;
    CGRect textSize = [name boundingRectWithSize:(CGSize){self.nameView.frame.size.width, 9001} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:13]}];
    //self.nameView.frameSize = textSize.size;
    [sheet setFrame:(CGRect){sheet.frame.origin, {sheet.frame.size.width, nominalH + textSize.size.height}} display:NO];
    self.nameView.stringValue = name;
    _name = name;
}

- (IBAction)saveImage:(id)sender {
    NSSavePanel *pan = [[NSSavePanel alloc] init];
    pan.message = NSLocalizedString(@"Where would you like to save the QR code?",
                                  @"displayed when you choose to export a qr code");
    pan.prompt = NSLocalizedString(@"Save", @"button title");
    pan.allowedFileTypes = @[@"png"];
    pan.nameFieldStringValue = [NSString stringWithFormat:@"%@.png", self.name];
    [pan beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            CGImageRef cg = [self.codeView.image CGImageForProposedRect:NULL context:nil hints:nil];
            NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:cg];
            bitmap.size = self.codeView.image.size;
            [[bitmap representationUsingType:NSPNGFileType properties:nil] writeToURL:pan.URL atomically:YES];
        }
    }];
}

- (IBAction)close:(id)sender {
    [NSApp endSheet:self.window returnCode:1];
}

@end
