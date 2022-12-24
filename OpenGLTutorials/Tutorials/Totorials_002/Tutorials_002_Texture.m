//
//  Tutorials_002_Texture.m
//  OpenGLTutorials
//
//  Created by Steven Deng on 2022/12/3.
//

#import "Tutorials_002_Texture.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface Tutorials_002_Texture() {
    GLint _vertexPosition;
    GLint _textureCoords;
    
    // 纹理参数
    GLuint _jpgTexture;
    GLuint _pngTexture;
    GLint _inputTextureUniformLoc;
    GLint _maskTextureUniformLoc;
    
    // 渲染yuv
    GLint _y_textureUniformLocation;
    GLint _uv_textureUniformLocation;
    // nv12
    GLuint _yTexture;
    GLuint _uvTexture;
    
    // yuv
//    GLuint _uTexture;
//    GLuint _vTexture;
}

@end


@implementation Tutorials_002_Texture

- (void)setupExtraEnv:(GLint)program {
    // 设置纹理
    _vertexPosition = glGetAttribLocation(program, "vertexPosition");
    _textureCoords = glGetAttribLocation(program, "textureCoords");
    glEnableVertexAttribArray(_vertexPosition);
    glEnableVertexAttribArray(_textureCoords);
    
    _inputTextureUniformLoc = glGetUniformLocation(program, "inputTexture");
    _maskTextureUniformLoc = glGetUniformLocation(program, "maskTexture");

    glGenTextures(1, &_jpgTexture);
    glGenTextures(1, &_pngTexture);

    [self setupTexture:_jpgTexture];
    [self setupTexture:_pngTexture];

    // YUV-nv12格式
//    _y_textureUniformLocation = glGetUniformLocation(program, "y_texture");
//    _uv_textureUniformLocation = glGetUniformLocation(program, "uv_texture");
//    _y_textureUniformLocation = glGetUniformLocation(program, "y_texture");
//    _uv_textureUniformLocation = glGetUniformLocation(program, "uv_texture");
//    [self setupTextureYUV_NV12];
    
    //
//    [self setupTextureYUV];
}

// 渲染图片
- (void)renderWithContext:(EAGLContext *)context
{
    //清屏 色
    glClearColor(1.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"jpg"];
    [self drawImageWithContext:context imagePath:filePath textureid:_jpgTexture];
    
    filePath = [[NSBundle mainBundle] pathForResource:@"bilinearfiltering" ofType:@"png"];
    [self drawImageWithContext:context imagePath:filePath textureid:_pngTexture];
    
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Public
// 渲染相机（texImage2D：注意 GL_BGRA）
-(void)renderWithContext:(EAGLContext *)context rgbData:(char*)rgbData width:(int)width height:(int)height
{
    // 目前同时使用SampleBufferDisplayView渲染导致只能渲染成功一个
    if ([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
    
    // type 需要与相机输出指定格式匹配
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 width,
                 height,
                 0,
                 GL_BGRA,
                 GL_UNSIGNED_BYTE,
                 rgbData);
    
    //清屏 色
    glClearColor(1.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 方式一：索引
//    const GLint Indices[] = {
//        0, 1, 3,
//        1, 2, 3
//    };
//    GLuint indexBuffer;
//    glGenBuffers(1, &indexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
//    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // 方式二：VAO绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  // GL_TRIANGLE_FAN
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)renderWithContext:(EAGLContext *)context YData:(char*)YData UVData:(char*)UVData width:(int)width height:(int)height
{
    //检查context
    if ([EAGLContext currentContext] != context) {
        [EAGLContext setCurrentContext:context];
    }
    glActiveTexture(GL_TEXTURE0 + 1);
    glBindTexture(GL_TEXTURE_2D, _yTexture);
    
    //确定采样器对应的哪个纹理，由于只使用一个，所以这句话可以不写
    glUniform1i(_y_textureUniformLocation,1);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE,
                 width, height,
                 0,
                 GL_LUMINANCE,
                 GL_UNSIGNED_BYTE,
                 YData);
 
    glActiveTexture(GL_TEXTURE0 + 0);
    glBindTexture(GL_TEXTURE_2D, _uvTexture);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_LUMINANCE_ALPHA,
                 width/2, height/2,
                 0,
                 GL_LUMINANCE_ALPHA,
                 GL_UNSIGNED_BYTE,
                 UVData);
//    glUniform1i(_uv_textureUniformLocation,0);
    //设置一些边缘的处理
    
    //清屏为白色
    glClearColor(1.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    //EACAGLContext 渲染OpenGL绘制好的图像到EACAGLLayer
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

//-(void)renderWithContext:(EAGLContext *)context YData:(char*)YData UData:(char*)UData VData:(char*)VData width:(int)width height:(int)height
//{
//    //检查context
//    if ([EAGLContext currentContext] != context) {
//        [EAGLContext setCurrentContext:context];
//    }
//
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, _yTexture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, YData);
//
//    glActiveTexture(GL_TEXTURE0 + 1);
//    glBindTexture(GL_TEXTURE_2D, _uTexture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, UData);
//
//    glActiveTexture(GL_TEXTURE0 + 2);
//    glBindTexture(GL_TEXTURE_2D, _vTexture);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, VData);
//
//    GLfloat vertices[] = {
//        1.0f, 1.0f,
//        1.0f, -1.0f,
//        -1.0f, -1.0f,
//        -1.0f, 1.0f,
//    };
//
//    // 纹理UV坐标（可以试试修改坐标顺序看看）
//    GLfloat textCoord[] = {
//        1.0f, 1.0f,
//        1.0f, 0.0f,
//        0.0f, 0.0f,
//        0.0f, 1.0f
//    };
//    glVertexAttribPointer(_vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
//    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE,0, textCoord);
//
//    //清屏为白色
//    glClearColor(1.0, 1.0, 1.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
//
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    //EACAGLContext 渲染OpenGL绘制好的图像到EACAGLLayer
//    [context presentRenderbuffer:GL_RENDERBUFFER];
//}


#pragma mark - Private
// 纹理顶点数据和纹理UV坐标一次上传（bufferData方式）
- (void)setupTexture:(GLuint)textureid
{
    glBindTexture(GL_TEXTURE_2D, textureid);
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

// 纹理顶点数据和纹理UV坐标分开上传（传指针方式）
- (void)setupTextureYUV_NV12
{
    // 纹理顶点
    GLfloat vertices[] = {
        1.0f, 1.0f,
        1.0f, -1.0f,
        -1.0f, -1.0f,
        -1.0f, 1.0f,
    };
    // 纹理UV坐标（可以试试修改坐标顺序看看）
//    GLfloat textCoord[] = {
//        1.0f, 1.0f,
//        1.0f, 0.0f,
//        0.0f, 0.0f,
//        0.0f, 1.0f
//    };
    // 通过修改纹理坐标，顺时针旋转90 (相机原始方向是横屏左向)
    GLfloat textCoord[] = {
        0, 1,
        1, 1,
        1, 0,
        0, 0,
    };
    
    glGenTextures(1, &_yTexture);
    glBindTexture(GL_TEXTURE_2D, _yTexture);
    //设置一些边缘环绕/采样的处理
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glGenTextures(1, &_uvTexture);
    glBindTexture(GL_TEXTURE_2D, _uvTexture);
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(textCoord), textCoord, GL_STATIC_DRAW);
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

//- (void)setupTextureYUV {
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
//
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, _yTexture);
//    //确定采样器对应的哪个纹理，由于只使用一个，所以这句话可以不写
////    glUniform1i(_y_texture,0);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    glActiveTexture(GL_TEXTURE0 + 1);
//    glBindTexture(GL_TEXTURE_2D, _uTexture);
////    glUniform1i(_u_texture,1);
//    //设置一些边缘的处理
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    glActiveTexture(GL_TEXTURE0 + 2);
//    glBindTexture(GL_TEXTURE_2D, _vTexture);
////    glUniform1i(_v_texture,2);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    // 方式二：传指针（js无法传指针，仅native可以, 必须texImage2D之后才能生效）
//    glVertexAttribPointer(_vertexPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
//    glVertexAttribPointer(_textureCoords, 2, GL_FLOAT, GL_FALSE,0, textCoord);
//}

// 绘制图片
- (void)drawImageWithContext:(EAGLContext *)context imagePath:(NSString *)filePath textureid:(GLuint)textureid
{
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"bilinearfiltering" ofType:@"png"];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    void *data = malloc(width * height * 4);
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(ctx, 0, height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(ctx, rect, cgImageRef);
    
    glActiveTexture(GL_TEXTURE0 + textureid);
    glBindTexture(GL_TEXTURE_2D, textureid);
    if (textureid == _jpgTexture) {
        glUniform1i(_maskTextureUniformLoc, textureid);
//        glUniform1i(_inputTextureUniformLocation, textureid);
    } else {
        glUniform1i(_inputTextureUniformLoc, textureid);
//        glUniform1i(_maskTextureUniformLocation, textureid);
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                 image.size.width, image.size.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    // 释放
    CGContextRelease(ctx);
    free(data);
    
    // 方式一：索引
    const GLint Indices[] = {
        0, 1, 3,
        0, 2, 3
    };
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // 方式二：VAO绘制
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  // GL_TRIANGLE_FAN
    
    //EACAGLContext 渲染OpenGL绘制好的图像到EACAGLLayer
//    [context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
