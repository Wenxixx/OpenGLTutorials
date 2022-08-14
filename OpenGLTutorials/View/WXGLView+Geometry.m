//
//  WXGLView+Geometry.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import "WXGLView+Geometry.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>

@implementation WXGLView (Geometry)

- (void)drawTriangle {
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
                          3,                    // size
                          GL_FLOAT,             // type
                          GL_FALSE,             // normalized?
                          sizeof(float)*3,      // stride
                          (void*)0
                          );
    
    // 背景
    glClearColor(0.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 绘制方式1: drawElements (通过指定的顶点索引绘制)
//    const GLint Indeces[] = {
//        0, 1, 2, 3
//    };
    
    // 创建并提交顶点索引到EBO
//    GLuint indexBuffer;
//    glGenBuffers(1, &indexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indeces), Indeces, GL_STATIC_DRAW);
//    glDrawElements(GL_TRIANGLES, 4, GL_UNSIGNED_INT, 0);
    
    // 绘制方式2: drawArrays
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)drawRectangle {
    int vertexPositionIndex = 0;
    glEnableVertexAttribArray(vertexPositionIndex);
    // 矩形顶点(通过索引绘制，实际只需要4个顶点就行)
    float vertices[] = {
        0.5f, 0.5f, 0.0f,
        -0.5f, 0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f,
//        0.5f, 0.5f, 0.0f,
//        -0.5f, -0.5f, 0.0f,
    };
    
    // 创建并提交顶点坐标到顶点VBO
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
    
    // 背景
//    glClearColor(0.0, 1.0, 1.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
    
    // 绘制方式1: drawElements (通过指定的顶点索引绘制)
    const GLint Indeces[] = {
        0, 1, 2,
        2, 3, 0
    };
    
    // 创建并提交顶点索引到EBO
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indeces), Indeces, GL_STATIC_DRAW);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    
    // 绘制方式2: drawArrays
    glDrawArrays(GL_TRIANGLES, 0, 6);  // 绘制矩形，需要绘制6个顶点
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}


@end
