//
//  Tutorials_001_Geometry.m
//  OpenGLTutorials
//
//  Created by Steven Deng on 2022/11/22.
//

#import "Tutorials_001_Geometry.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES3/gl.h>
#import <UIKit/UIKit.h>

@implementation Tutorials_001_Geometry

#pragma mark - WXRenderProtocol
- (void)setupExtraEnv:(GLint)program {
    // do nothing
}


- (void)renderWithContext:(EAGLContext *)context {
    // 绘制三角形
    [self drawTriangle:context];
    // 绘制矩形
    [self drawRectangle:context];
}

- (void)drawTriangle:(EAGLContext *)context {
    int vertexPositionIndex = 0;
    glEnableVertexAttribArray(vertexPositionIndex);
    // 三角形顶点
    float vertices[] = {
        0.0f, 1.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
    };
    
    // 创建并提交顶点坐标到顶点VBO
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(vertexPositionIndex,  // attribute 0. No particular reason for 0, but must match the layout in the shader.
                          3,                    // size 第二个参数指定顶点属性的大小。顶点属性是一个vec3，它由3个值组成，所以大小是3。
                          GL_FLOAT,             // type 第三个参数指定数据的类型，这里是GL_FLOAT(GLSL中vec*都是由浮点数值组成的)。
                          GL_FALSE,             // normalized 下个参数定义我们是否希望数据被标准化(Normalize)。如果我们设置为GL_TRUE，所有数据都会被映射到0（对于有符号型signed数据是-1）到1之间。我们把它设置为GL_FALSE。
                          sizeof(float)*3,      // stride 步长
                          (void*)0              // 它表示位置数据在缓冲中起始位置的偏移量(Offset)。由于位置数据在数组的开头，所以这里是0。我们会在后面详细解释这个参数。
                          );
    
    // 背景
    glClearColor(0.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 绘制方式1: drawElements (通过指定的顶点索引绘制,可减少bufferData顶点数据)
    const GLint Indeces[] = {
        0, 1, 2,
    };
    // 创建并提交顶点索引到EBO
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indeces), Indeces, GL_STATIC_DRAW);
    glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, 0);
    
    // 绘制方式2: drawArrays
//    glDrawArrays(GL_TRIANGLES, 0, 3);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawRectangle:(EAGLContext *)context {
    int vertexPositionIndex = 0;
    glEnableVertexAttribArray(vertexPositionIndex);
    // 矩形顶点(通过索引绘制，实际只需要4个顶点就行)
    float vertices[] = {
        0.5f, 0.5f, 0.5f,
        -0.5f, 0.5f, 1.0f,
        -0.5f, -0.5f, -0.5f,
        0.5f, -0.5f, -1.0f,
        0.5f, 0.5f, 0.5f,
    };
    
    // 方式一：创建并提交顶点坐标到顶点VBO（推荐，webgl-js无法传指针）
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(vertexPositionIndex,  // attribute 0. No particular reason for 0, but must match the layout in the shader.
                          3,                    // size
                          GL_FLOAT,             // type
                          GL_FALSE,             // normalized?
                          sizeof(float)*3,      // stride
                          (void*)0
                          );
    // 方式二：传指针，无需上传VBO
//    glVertexAttribPointer(vertexPositionIndex,  // attribute 0. No particular reason for 0, but must match the layout in the shader.
//                          3,                    // size
//                          GL_FLOAT,             // type
//                          GL_FALSE,             // normalized?
//                          sizeof(float)*3,      // stride
//                          vertices
//                          );
    
    // 背景
//    glClearColor(0.0, 1.0, 1.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
    
    /*
     GL_TRIANGLES / GL_TRIANGLE_STRIP / GL_TRIANGLE_FAN: 三角形方式填充
     GL_POINTS: 点画
     GL_LINE_STRIP：连线
     **/
    // 绘制方式1: drawElements (通过指定的顶点索引绘制)
    const GLint Indeces[] = {
        0, 1, 2,
        2, 3, 0
    };
    // 绘制方式1: drawElements
    // 创建并提交顶点索引到EBO
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indeces), Indeces, GL_STATIC_DRAW);
    glDrawElements(GL_LINE_STRIP, 6, GL_UNSIGNED_INT, 0);
    
    // 绘制方式2: drawArrays
    // GL_TRIANGLE_STRIP: 绘制填充矩形
    // GL_LINE_STRIP: 绘制填充矩形
//    glDrawArrays(GL_LINE_STRIP, 0, 5);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}


@end
