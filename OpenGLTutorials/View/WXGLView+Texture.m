//
//  WXGLView+Texture.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import "WXGLView+Texture.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation WXGLView (Texture)

- (void)drawImageWithProgram:(GLuint)program
{
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"bilinearfiltering" ofType:@"png"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"jpg"];
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
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                 image.size.width, image.size.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    // 释放
    CGContextRelease(ctx);
    free(data);
    
    //清屏
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
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //EACAGLContext 渲染OpenGL绘制好的图像到EACAGLLayer
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Public
-(void)renderWithRGBData:(char*)rgbData width:(int)width height:(int)height
{
    // 目前同时使用SampleBufferDisplayView渲染导致只能渲染成功一个
//    dispatch_sync(self.renderQueue, ^{
        if ([EAGLContext currentContext] != self.context) {
            [EAGLContext setCurrentContext:self.context];
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

        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
//    });
}



@end
