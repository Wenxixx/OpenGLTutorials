//
//  WXCVPixelBufferUtil.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/12.
//

#import "WXCVPixelBufferUtil.h"
#import <OpenGLES/ES2/glext.h>

@implementation WXCVPixelBufferUtil


+ (CVPixelBufferPoolRef)createPixelBufferPool:(int)width height:(int)height format:(int)format
{
    CVPixelBufferPoolRef pixelBufferPool = NULL;
    CVReturn result;
    NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
    
    if (format == GL_BGRA) {
        [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                       forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    } else {
        [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                       forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    }    
    [attributes setObject:[NSNumber numberWithInt:width]
                   forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithInt:height]
                   forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setObject:@(16)
                   forKey:(NSString *)kCVPixelBufferBytesPerRowAlignmentKey];
    [attributes setObject:[NSDictionary dictionary]
                   forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    result = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef)attributes, &pixelBufferPool);
    if (result != kCVReturnSuccess) {
        pixelBufferPool = NULL;
        return NULL;
    }
  
    return pixelBufferPool;
}

+ (void)releasePixelBufferPool:(CVPixelBufferPoolRef)pixelBufferPool
{
    if (pixelBufferPool) {
        CVPixelBufferPoolFlush(pixelBufferPool, kCVPixelBufferPoolFlushExcessBuffers);
        CVPixelBufferPoolRelease(pixelBufferPool);
    }
}

+ (CVPixelBufferRef)createPixelBuffer:(int)width
                               height:(int)height
                                 pool:(CVPixelBufferPoolRef)pool
                               status:(CVReturn *)status
{
    CVPixelBufferRef pixelBuffer = NULL;
    if (pool) {
        *status = CVPixelBufferPoolCreatePixelBuffer(NULL, pool, &pixelBuffer);

    } else {
        NSDictionary *options = @{
            (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
        };
        *status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                     kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options,
                                     &pixelBuffer);
    }
    
    if (pixelBuffer && (*status) == kCVReturnSuccess) {
        
    }
    return pixelBuffer;
}


+ (CMSampleBufferRef)createSmapleBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return NULL;
    }
    
    // 不设置具体时间信息
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    
    // 获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true,
                                                NULL, NULL, videoInfo, &timing, &sampleBuffer);
    // set attachment
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    
    if (sampleBuffer) {
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        if (dict) {
            CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        }
    }
    
//    CFRelease(pixelBuffer);
    if (videoInfo) {
        CFRelease(videoInfo);
    }
    
    return sampleBuffer;
}

@end
