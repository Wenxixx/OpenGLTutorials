//
//  YUVShader.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#ifndef YUVShader_h
#define YUVShader_h

#import "WXOpenGLDefine.h"

NSString *const nv12vertexShaderString = SHADER_STRING
(
 attribute vec4 vertexPosition;
 attribute vec2 textureCoords;
 varying  vec2 textureCoordsOut;
 void main(void) {
     gl_Position = vertexPosition;
     textureCoordsOut = textureCoords;
 }
);

NSString *const nv12fragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordsOut;
 
 uniform sampler2D y_texture;
 uniform sampler2D uv_texture;
 
 void main(void) {
     
     highp float y = texture2D(y_texture, textureCoordsOut).r;
     highp float u = texture2D(uv_texture, textureCoordsOut).r - 0.5 ;
     highp float v = texture2D(uv_texture, textureCoordsOut).a -0.5;

     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;

     gl_FragColor = vec4(r,g,b,1.0);
 }
);

NSString *const yuvfragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordsOut;

 uniform sampler2D y_texture;
 uniform sampler2D u_texture;
 uniform sampler2D v_texture;

 void main(void) {

     highp float y = texture2D(y_texture, textureCoordsOut).r;
     highp float u = texture2D(u_texture, textureCoordsOut).r - 0.5;
     highp float v = texture2D(v_texture, textureCoordsOut).r - 0.5;

     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;

     gl_FragColor = vec4(r,g,b,1.0);

 }
);


#endif /* YUVShader_h */
