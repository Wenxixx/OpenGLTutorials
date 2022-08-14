//
//  WXSampleBufferDisplayView.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXSampleBufferDisplayView : UIView

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)displayWithRGBBuffer:(uint8_t*)buffer width:(int)width height:(int)height;

- (void)displayWithNV12yBuffer:(uint8_t*)yBuffer uvBuffer:(uint8_t*)uvBuffer width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
