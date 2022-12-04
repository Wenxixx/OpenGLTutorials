//
//  Practices_001.m
//  OpenGLTutorials
//
//  Created by Steven Deng on 2022/11/22.
//

#import "Practices_001.h"
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES3/gl.h>
#import <UIKit/UIKit.h>

@implementation Practices_001

#pragma mark - WXRenderProtocol

- (void)setupExtraEnv:(GLint)program {
    // do nothing
}


- (void)renderWithContext:(EAGLContext *)context {
//    [self drawTwoTriangle:context];
    
    [self drawTwoSameTriangles:context];
}

// 练习1：绘制两个相连的三角形 https://learnopengl-cn.github.io/01%20Getting%20started/04%20Hello%20Triangle/
- (void)drawTwoTriangle:(EAGLContext *)context {
    int vertexPositionIndex = 0;
    glEnableVertexAttribArray(vertexPositionIndex);
    float vertices[] = {
        -1.0f, 1.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
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
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

// 创建相同的两个三角形，但对它们的数据使用不同的VAO和VBO
- (void)drawTwoSameTriangles:(EAGLContext *)context
{
    float verteices_first[] = {
        -1.0f, 1.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f,
    };
    
    float verteices_second[] = {
        0.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
    };
    
    GLuint VBOs[2], VAOs[2];
    glGenVertexArrays(2, VAOs);
    glGenBuffers(2, VBOs);
    
    glBindVertexArray(VAOs[0]);
//    glBindBuffer(GL_ARRAY_BUFFER, VBOs[0]);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(verteices_first), verteices_first, GL_STATIC_DRAW);
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
//    glEnableVertexAttribArray(0);
    
    glBindVertexArray(VAOs[1]);
//    glBindBuffer(GL_ARRAY_BUFFER, VBOs[1]);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(verteices_second), verteices_second, GL_STATIC_DRAW);
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
//    glEnableVertexAttribArray(0);

    // 背景
    glClearColor(0.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindVertexArray(VAOs[0]);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    glBindVertexArray(VAOs[1]);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    [context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
