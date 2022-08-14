//
//  WXGLView.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/8.
//

#import "WXGLView.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "WXGLView+Geometry.h"
#import "WXGLView+Texture.h"

#import "Shader.h"
#import "TextureShader.h"

/**
 WXGLView: 渲染管线通用流程准备：
    GL上下文，
    framebuffer，
    renderBuffer，
    shader编译，装载，
    program链接
 WXGLView+Geometry分类
    绘制三角形
    绘制矩形
 WXGLView+Texture
    纹理绘制图片
    纹理绘制相机 (rgba, yuv)
 */
@interface WXGLView()

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;

@end


@implementation WXGLView
{
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLuint _program;
    
    GLint   _backingWidth;
    GLint   _backingHeight;
    
    // 纹理参数
    GLint _texture;
    GLint _vertexPosition;
    GLint _textureCoords;
    
    GLuint _rgbTexture;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
        [self render];
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
        
    [self prepareShaderWithType:GLShaderTypeNormal];  // GLShaderTypeNormal GLShaderTypeTexture
    [self attachShaderAndLinkProgram];
}

- (void)render {
    // 绘制三角形
    [self drawTriangle];
    // 绘制矩形
    [self drawRectangle];
    
    // 渲染纹理
//    [self setupTexture2];
//    [self drawImageWithProgram:_program];
    // 渲染纹理(复用程序)
    [self renderTextureReuseProgram];
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
    
    [self resetShader];

    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
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

// 根据渲染几何图形/纹理加载对应 顶点着色器 / 片元着色器并编译
- (void)prepareShaderWithType:(GLShaderType)shaderType
{
    self.shaderType = shaderType;
    // delete
    [self resetShader];
    
    // 创建顶点着色器
    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    NSString *vertexShader;
    NSString *fragmentShader;
    switch (shaderType) {
        case GLShaderTypeNormal: {
            vertexShader = vertexShaderString;
            fragmentShader = fragmentShaderString;
        }
            break;
        case GLShaderTypeTexture: {
            vertexShader = textureVertexShaderString;
            fragmentShader = textureFragmentShaderString;
        }
            break;
        default: {
            vertexShader = vertexShaderString;
            fragmentShader = fragmentShaderString;
        }
            break;
    }
    const GLchar* const vertexShaderSource = (GLchar*)[vertexShader UTF8String];
    GLint vertexShaderLength = (GLint)[vertexShader length];
    glShaderSource(_vertexShader, 1, &vertexShaderSource, &vertexShaderLength);
    glCompileShader(_vertexShader);
   
    // 打印日志
    GLint logLen;
    glGetShaderiv(_vertexShader, GL_INFO_LOG_LENGTH, &logLen);
    if (logLen > 0) {
        GLchar *log = (GLchar*)malloc(logLen);
        glGetShaderInfoLog(_vertexShader, logLen, &logLen, log);
        NSLog(@"%s", log);
        free(log);
    }
    
    // 创建片元着色器
    _fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    const GLchar* const fragmentShaderSource = (GLchar*)[fragmentShader UTF8String];
    GLint fragmentShaderLength = (GLint)[fragmentShader length];
    glShaderSource(_fragmentShader, 1, &fragmentShaderSource, &fragmentShaderLength);
    glCompileShader(_fragmentShader);

    glGetShaderiv(_fragmentShader, GL_INFO_LOG_LENGTH, &logLen);
    if (logLen > 0) {
        GLchar *log = (GLchar*)malloc(logLen);
        glGetShaderInfoLog(_fragmentShader, logLen, &logLen, log);
        NSLog(@"%s", log);
        free(log);
    }
}

// 创建程序并装载着色器 & 链接使用程序
- (void)attachShaderAndLinkProgram
{
    if (!_program) {
        _program = glCreateProgram();
    }
    
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);
    
    glLinkProgram(_program);
    glUseProgram(_program);
    
    if (_shaderType == GLShaderTypeTexture) {
        _texture = glGetUniformLocation(_program, "inputTexture");
        _vertexPosition = glGetAttribLocation(_program, "vertexPosition");
        _textureCoords = glGetAttribLocation(_program, "textureCoords");
        
        glEnableVertexAttribArray(_vertexPosition);
        glEnableVertexAttribArray(_textureCoords);
    }
}

#pragma mark - Reuse
// 着色器可以卸载重新挂在新的
- (void)renderTextureReuseProgram
{
    // 重写渲染Texture
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // detach原来挂载的shader（一个program只能挂载唯一顶点/片元着色器）
        [self detachShader];
        
        // 生成新的shader并挂载
        [self prepareShaderWithType:GLShaderTypeTexture];
        [self attachShaderAndLinkProgram];
        
        [self setupTexture];
        [self drawImageWithProgram:self->_program];
    });
}

// 卸载着色器
- (void)detachShader
{
    glDetachShader(_program, _vertexShader);
    glDetachShader(_program, _fragmentShader);
}

// 删除释放着色器数据
- (void)resetShader
{
    if (_vertexShader) {
        glDeleteShader(_vertexShader);
        _vertexShader = 0;
    }
    
    if (_fragmentShader) {
        glDeleteShader(_fragmentShader);
        _fragmentShader = 0;
    }
}

// 纹理顶点数据 和 纹理UV坐标一次上传bufferData
- (void)setupTexture
{
    glGenTextures(1, &_rgbTexture);
    glBindTexture(GL_TEXTURE_2D, _rgbTexture);
    
    //设置一些边缘的处理
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 或者可以将纹理坐标单独写 (上传完顶点数据后绑定纹理坐标)
    // 可以试试修改坐标顺序看看（顶点顺序 和 UV坐标顺序不一致）
    float vertices[] = {
        -1, 1, 0.0f,  0, 1,
        1, 1, 0.0f, 1, 1,
        -1, -1, 0.0f, 0, 0,
        1, -1, 0.0f,  1, 0
    };
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(_vertexPosition,
                          3,
                          GL_FLOAT,
                          GL_FALSE,
                          5 * sizeof(float),
                          (void*)0
                          );
        
    glVertexAttribPointer(_textureCoords,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          5 * sizeof(float),
                          (void*)(sizeof(float) *3)
                          );
}

// 纹理顶点数据 和 纹理UV坐标 分开上传bufferData
- (void)setupTexture2
{
    // 顶点
//    float vertices[] = {
//        0.5f, 0.5f, 0.0f,
//        0.5f, -0.5f, 0.0f,
//        -0.5f, -0.5f, 0.0f,
//        -0.5f, 0.5f, 0.0f,
//    };
    
    GLfloat vertices[] = {
        1.0f, 1.0f,
        1.0f, -1.0f,
        -1.0f, -1.0f,
        -1.0f, 1.0f,
    };

    // 可以试试修改坐标顺序看看
    GLfloat textures[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f
    };
    
    glBindTexture(GL_TEXTURE_2D, _rgbTexture);
    
    //设置一些边缘的处理
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
   
    // 方式一：bufferData提交数据
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(_vertexPosition,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          2 * sizeof(float),
                          (void*)0
                          );
        
    // 纹理坐标单独VBO
    GLuint textureBuffer;
    glGenBuffers(1, &textureBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textures), textures, GL_STATIC_DRAW);
    glVertexAttribPointer(_textureCoords,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          2 * sizeof(float),
                          (void*)0
                          );
    
    // 方式二：传指针（js无法传指针，仅native可以, 必须texImage2D之后才能生效）
//    glVertexAttribPointer(_vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
//    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE, 0, textures);
}

@end
