//
//  WXGLView.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/8.
//

#import "WXGLView.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
// 绘制三角形
// 绘制矩形
#import "Shader.h"
#import "Tutorials_001_Geometry.h"
#import "Practices_001.h"

// 纹理绘制图片
// 纹理绘制相机 (rgba, yuv)
#import "TextureShader.h"
#import "YUVShader.h"
#import "Tutorials_002_Texture.h"

/**
 WXGLView: 渲染管线通用流程准备：
    GL上下文，
    framebuffer，
    renderBuffer，
    shader编译，装载，
    program链接
 */
@interface WXGLView()

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) id<WXRenderProtocol> render;

@end


@implementation WXGLView
{
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    
    GLint   _backingWidth;
    GLint   _backingHeight;
    
    GLuint _program;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
//        [self createPrograme:vertexShaderString fragmentShader:fragmentShaderString];
//        self.render = [[Tutorials_001_Geometry alloc] init];
//        self.render = [[Practices_001 alloc] init];
        
        // 纹理渲染图片（rgba）
//        [self createPrograme:textureVertexShaderString fragmentShader:textureFragmentShaderString];
//        self.render = [[Tutorials_002_Texture alloc] init];
        
        // 纹理渲染相机（rgba / nv12 / yuv）
        [self createPrograme:textureVertexShaderString fragmentShader:textureFragmentShaderString]; // rgba
//        [self createPrograme:nv12vertexShaderString fragmentShader:nv12fragmentShaderString]; // nv12
//        [self createPrograme:nv12vertexShaderString fragmentShader:yuvfragmentShaderString]; // yuvv12
        self.render = [[Tutorials_002_Texture alloc] init];
        
        
        [self.render setupExtraEnv:_program];
        [self.render renderWithContext:_context];
    }
    return self;
}

- (void)commonInit {
//    _renderQueue = dispatch_queue_create("renderQueue", DISPATCH_QUEUE_SERIAL);
    [self prepareLayer];
    // 设置gl环境
    [self setupGLContext];
    // 准备renderBuffer
    [self prepareRenderBuffer];
    // 准备frameBuffer
    [self prepareFrameBuffer];
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)dealloc
{
    if (_frameBuffer) {
        glDeleteBuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    if (_renderBuffer) {
        glDeleteBuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    _context = nil;
}

#pragma mark - Common
- (void)prepareLayer
{
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    // 设置不透明
    self.eaglLayer.opaque = YES;
    self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                         kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupGLContext
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
}

- (void)prepareRenderBuffer
{
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
}

- (void)prepareFrameBuffer
{
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _renderBuffer);
}

- (void)createPrograme:(NSString* const)vertexString
        fragmentShader:(NSString* const)fragmentString {
    
    GLint vertextShader = glCreateShader(GL_VERTEX_SHADER);
    const GLchar* const vertexShaderSource = (GLchar*)[vertexString UTF8String];
    GLint vertexShaderLength = (GLint)[vertexString length];
    glShaderSource(vertextShader, 1, &vertexShaderSource, &vertexShaderLength);
    glCompileShader(vertextShader);
   
    // 打印日志
    GLint logLen;
    glGetShaderiv(vertextShader, GL_INFO_LOG_LENGTH, &logLen);
    if (logLen > 0) {
        GLchar *log = (GLchar*)malloc(logLen);
        glGetShaderInfoLog(vertextShader, logLen, &logLen, log);
        NSLog(@"%s", log);
        free(log);
    }
    
    // 创建片元着色器
    GLint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    const GLchar* const fragmentShaderSource = (GLchar*)[fragmentString UTF8String];
    GLint fragmentShaderLength = (GLint)[fragmentString length];
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, &fragmentShaderLength);
    glCompileShader(fragmentShader);

    glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logLen);
    if (logLen > 0) {
        GLchar *log = (GLchar*)malloc(logLen);
        glGetShaderInfoLog(fragmentShader, logLen, &logLen, log);
        NSLog(@"%s", log);
        free(log);
    }
    
    _program = glCreateProgram();
    glAttachShader(_program, vertextShader);
    glAttachShader(_program, fragmentShader);
    
    glDeleteShader(vertextShader);
    glDeleteShader(fragmentShader);
    
    glLinkProgram(_program);
    glUseProgram(_program);
    glDeleteProgram(_program);
}

#pragma mark - Public
- (void)renderWithCameraRgbData:(char*)rgbData width:(int)width height:(int)height
{
    [(Tutorials_002_Texture *)self.render renderWithContext:_context rgbData:rgbData width:width height:height];
}


- (void)renderWithYData:(char*)YData UVData:(char*)UVData width:(int)width height:(int)height {
    [(Tutorials_002_Texture *)self.render renderWithContext:_context YData:YData UVData:UVData width:width height:height];
    // TODO: 拆成y,u,v三张纹理
}



@end
