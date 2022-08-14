//
//  WXCVPixelBufferUtil.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXCVPixelBufferUtil : NSObject

+ (CVPixelBufferPoolRef)createPixelBufferPool:(int)width
                                       height:(int)height
                                       format:(int)format;

+ (void)releasePixelBufferPool:(CVPixelBufferPoolRef)pixelBufferPool;

+ (CVPixelBufferRef)createPixelBuffer:(int)width
                               height:(int)height
                                 pool:(CVPixelBufferPoolRef)pool
                               status:(CVReturn *)status;

+ (CMSampleBufferRef)createSmapleBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
