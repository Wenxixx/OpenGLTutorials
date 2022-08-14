//
//  TextureShader.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/9.
//

#ifndef TextureShader_h
#define TextureShader_h

#import "WXOpenGLDefine.h"

NSString *const textureVertexShaderString = SHADER_STRING
(
 // attribute关键字 定义传入shader的变量
    attribute vec4 vertexPosition;
    attribute vec2 textureCoords;
    varying   vec2 textureCoordsOut;
    void main(void) {
        gl_Position = vertexPosition;
        textureCoordsOut = textureCoords;
    }
);

NSString *const textureFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordsOut;
 
    uniform sampler2D inputTexture;
    void main(void) {
        gl_FragColor = texture2D(inputTexture, textureCoordsOut);
    }
);

#endif /* TextureShader_h */
