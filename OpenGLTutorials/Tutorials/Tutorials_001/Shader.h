//
//  Shader.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/9.
//

#ifndef Shader_h
#define Shader_h

#import "WXOpenGLDefine.h"

NSString *const vertexShaderString = SHADER_STRING
(
    attribute vec4 vertexPosition;
    varying vec4 vertexColor;
    void main(void) {
        // 将顶点坐标y翻转处理
//        gl_Position = vec4(vertexPosition.x, -vertexPosition.y, vertexPosition.z, vertexPosition.w);
//        vertexColor = vec4(0.5, 0, 0, 1.0);
        gl_Position = vertexPosition;
        vertexColor = vec4(vertexPosition.xyz, 1.0);
    }
 );

NSString *const fragmentShaderString = SHADER_STRING
(
   varying highp vec4 vertexColor;
    void main(void){
        gl_FragColor = vertexColor;
    }
 );

#endif /* Shader_h */
