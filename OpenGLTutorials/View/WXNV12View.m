//
//  WXNV12View.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import "WXNV12View.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>

#import "YUVShader.h"

@interface WXNV12View ()

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *context;

@end

@implementation WXNV12View
{
    GLuint _frameBufferId;
    GLuint _renderBufferId;
    
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLuint _program;
    
    GLint   _backingWidth;
    GLint   _backingHeight;
    
    // 纹理缓冲（nv12）
    GLuint _yTexture;
    GLuint _uvTexture;
    // 纹理
    GLint _y_texture;
    GLint _uv_texture;
    
    // 纹理（YUV分量）
//    GLint _y_texture;
//    GLint _u_texture;
//    GLint _v_texture;
//
//    GLuint _yTexture;
//    GLuint _uTexture;
//    GLuint _vTexture;

    
    // 顶点位置
    GLint _vertexPosition;
    
    // 纹理坐标
    GLint _textureCoords;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // 设置gl环境
        [self setupGLContext];
        
        // 准备renderBuffer
        [self prepareRenderBuffer];
        
        // 准备frameBuffer
        [self prepareFrameBuffer];
        
        // 准备着色器
        [self prepareShader];
        
        // 生成程序
        [self genProgram];
    }
    return self;
}


+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)dealloc
{
    if (_frameBufferId) {
        glDeleteBuffers(1, &_frameBufferId);
        _frameBufferId = 0;
    }
    
    if (_renderBufferId) {
        glDeleteBuffers(1, &_renderBufferId);
        _renderBufferId = 0;
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

- (void)setupGLContext
{
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    // 设置不透明
    self.eaglLayer.opaque = YES;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
}

- (void)prepareRenderBuffer
{
    glGenRenderbuffers(1, &_renderBufferId);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBufferId);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
}

- (void)prepareFrameBuffer
{
    glGenFramebuffers(1, &_frameBufferId);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferId);
    
    glViewport(0, 0, _backingWidth, _backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _renderBufferId);
}

- (void)prepareShader
{
    // delete
    [self resetShader];
    
    // 创建顶点着色器
    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    NSString *vertexShader = nv12vertexShaderString;
    NSString *fragmentShader = nv12fragmentShaderString;
    
    const GLchar* const vertexShaderSource = (GLchar*)[vertexShader UTF8String];
    GLint vertexShaderLength = (GLint)[vertexShader length];
    // 读取shader
    glShaderSource(_vertexShader, 1, &vertexShaderSource, &vertexShaderLength);
    // 编译shader
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

- (void)genProgram
{
    _program = glCreateProgram();
    
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);
    
    glLinkProgram(_program);
    glUseProgram(_program);
    
    //获取并保存参数位置
    _y_texture = glGetUniformLocation(_program, "y_texture");
    _uv_texture = glGetUniformLocation(_program, "uv_texture");
    
    //分配缓冲
    glGenTextures(1, &_yTexture);
    glGenTextures(1, &_uvTexture);
    
    _vertexPosition = glGetAttribLocation(_program, "vertexPosition");
    _textureCoords = glGetAttribLocation(_program, "textureCoords");
    
    glEnableVertexAttribArray(_vertexPosition);
    glEnableVertexAttribArray(_textureCoords);
}


//-(void)renderWithYData:(char*)YData UData:(char*)UData VData:(char*)VData width:(int)width height:(int)height
//{
//    //检查context
//    if ([EAGLContext currentContext] != self.context)
//    {
//        [EAGLContext setCurrentContext:self.context];
//    }
//
//    GLfloat vertices[] = {
//        -1,-1,
//        1,-1,
//        -1,1,
//        1,1,
//
//    };
//    GLfloat textCoord[] = {
//        0.0f, 1.0f,
//        1.0f, 1.0f,
//        0.0f, 0.0f,
//        1.0f, 0.0f,
//    };
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, _yTexture);
//    //确定采样器对应的哪个纹理，由于只使用一个，所以这句话可以不写
//    glUniform1i(_y_texture,0);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, YData);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//
//    glActiveTexture(GL_TEXTURE0 + 1);
//
//    glBindTexture(GL_TEXTURE_2D, _uTexture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, UData);
//    glUniform1i(_u_texture,1);
//
//
//    //设置一些边缘的处理
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    glActiveTexture(GL_TEXTURE0 + 2);
//
//    glBindTexture(GL_TEXTURE_2D, _vTexture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, VData);
//    glUniform1i(_v_texture,2);
//
//
//    //设置一些边缘的处理
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//
//    glVertexAttribPointer(_vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
//    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE,0, textCoord);
//
//    //清屏为白色
//    glClearColor(1.0, 1.0, 1.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
//
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    //EACAGLContext 渲染OpenGL绘制好的图像到EACAGLLayer
//    [_context presentRenderbuffer:GL_RENDERBUFFER];
//}

-(void)renderWithYData:(char*)YData UVData:(char*)UVData width:(int)width height:(int)height
{
    //检查context
    if ([EAGLContext currentContext] != self.context)
    {
        [EAGLContext setCurrentContext:self.context];
    }
    
    GLfloat vertices[] = {
        -1,  1,
        1,   1,
        -1, -1,
        1,  -1,
    };
    
    GLfloat textCoord[] = {
        0, 1,
        1, 1,
        0, 0,
        1, 0,
    };
    
    // 通过修改纹理坐标，顺时针旋转90
//    GLfloat textCoord[] = {
//        0, 0,
//        0, 1,
//        1, 0,
//        1, 1,
//    };
    
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, _yTexture);
    //确定采样器对应的哪个纹理，由于只使用一个，所以这句话可以不写
    glUniform1i(_y_texture,1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, YData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_2D, _uvTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width/2, height/2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, UVData);
    glUniform1i(_uv_texture,0);
    //设置一些边缘的处理
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glVertexAttribPointer(_vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE,0, textCoord);
    
    //清屏为白色
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //EACAGLContext 渲染OpenGL绘制好的图像到EACAGLLayer
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
