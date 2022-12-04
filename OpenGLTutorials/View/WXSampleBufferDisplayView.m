//
//  WXSampleBufferDisplayView.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import "WXSampleBufferDisplayView.h"
#import "WXCVPixelBufferUtil.h"
#import <OpenGLES/ES2/glext.h>

@interface WXSampleBufferDisplayView () {
    CVPixelBufferPoolRef _pixelBufferPool;
    
    // add
    CVPixelBufferRef  _pixelBuffer;
    
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef    _cvtexture;
    
    GLint _textureWidth;
    GLint _textureHeight;
    
    GLint _textureId;
    
    GLuint _frameBuffer;
    GLuint _renderBuffer;
}

@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;
@property (nonatomic, strong) EAGLContext *context;

@end

@implementation WXSampleBufferDisplayView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self createLayer];
        _textureWidth = 640;
        _textureHeight = 480;
        [self createPixelBufferPool:_textureWidth
                             height:_textureHeight
                             format:GL_BGRA];

        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (_context) {
            //
            if ([EAGLContext currentContext] != _context) {
                [EAGLContext setCurrentContext:_context];
                [self setupBuffers];
            }
        }
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [CATransaction setDisableActions:YES];
    self.displayLayer.frame = self.bounds;
}

-(void)createLayer
{
    self.displayLayer = [AVSampleBufferDisplayLayer layer];
    self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.displayLayer];
}

- (void)setupBuffers
{
    // setup framebuffer
    glGenFramebuffers(1, &_frameBuffer);

    //
    int preTexture = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &preTexture);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // create render pixebuffer
    [self setupCVTexture];
    
    // bind
    glBindTexture(GL_TEXTURE_2D, _textureId);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _textureId, 0);
    glBindTexture(GL_TEXTURE_2D, (GLuint)preTexture);
}

- (void)setupCVTexture
{
    int preTexture = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &preTexture);
    
    // create cv buffer
    CVReturn status;
    _pixelBuffer = [WXCVPixelBufferUtil createPixelBuffer:_textureWidth
                                                   height:_textureHeight
                                                     pool:_pixelBufferPool
                                                   status:&status];
    if (!_pixelBuffer) {
        return;
    }
    
    // create cv texture cache
    if (!_textureCache) {
        // CVEAGLContext
        status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL,  _context, NULL, &_textureCache);
        if (status != kCVReturnSuccess) {
            return;
        }
    }
    
    // create cv texture
    status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          _textureCache,
                                                          _pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RGBA,
                                                          _textureWidth,
                                                          _textureHeight,
                                                          GL_BGRA,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &_cvtexture);
    if (status != kCVReturnSuccess || !_cvtexture) {
        return;
    }
    
    _textureId = CVOpenGLESTextureGetName(_cvtexture);
    
    // bind texture
    glBindTexture(GL_TEXTURE_2D, _textureId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, (GLuint)preTexture);
}

#pragma mark - Public
- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
}

- (void)displayWithRGBBuffer:(uint8_t*)buffer width:(int)width height:(int)height {
    CVReturn result;
    CVPixelBufferRef pixelBuffer = [WXCVPixelBufferUtil createPixelBuffer:width
                                                                   height:height
                                                                     pool:_pixelBufferPool
                                                                   status:&result];
    if (result != kCVReturnSuccess) {
        pixelBuffer = NULL;
        return;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* base = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    memcpy(base, buffer, width * height * 4);
    if (base == NULL) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    [self displayPixelBuffer:pixelBuffer];
    CFRelease(pixelBuffer);
    pixelBuffer = NULL;
}

- (void)displayWithNV12yBuffer:(uint8_t*)yBuffer uvBuffer:(uint8_t*)uvBuffer width:(int)width height:(int)height {
    CVReturn result;
    CVPixelBufferRef pixelBuffer = [WXCVPixelBufferUtil createPixelBuffer:width
                                                                   height:height
                                                                     pool:_pixelBufferPool
                                                                   status:&result];
    if (result != kCVReturnSuccess) {
        pixelBuffer = NULL;
        return;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* y_base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(y_base, yBuffer, width * height * 1);
    if (y_base == NULL) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return;
    }
    
    void *uv_base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(uv_base, uvBuffer, width * height * 0.5);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    [self displayPixelBuffer:pixelBuffer];
    CFRelease(pixelBuffer);
    pixelBuffer = NULL;
}

#pragma mark - Private

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return;
    }
    CMSampleBufferRef sampleBuffer = [WXCVPixelBufferUtil createSmapleBuffer:pixelBuffer];
    if (self.displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [self.displayLayer flush];
    }
    
    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
}


- (void)createPixelBufferPool:(int)width
                       height:(int)height
                       format:(int)format
{
    if (_pixelBufferPool) {
        [WXCVPixelBufferUtil releasePixelBufferPool:_pixelBufferPool];
        _pixelBufferPool = NULL;
    }
    
    _pixelBufferPool = [WXCVPixelBufferUtil createPixelBufferPool:width
                                                           height:height
                                                           format:format];
}

@end
