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
    void main(void) {
        gl_Position = vertexPosition;
    }
 );

NSString *const fragmentShaderString = SHADER_STRING
(
    void main(void){
        gl_FragColor = vec4(1, 0, 0, 1);
    }
 );

#endif /* Shader_h */
