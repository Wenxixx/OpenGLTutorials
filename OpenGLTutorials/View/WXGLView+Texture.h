//
//  WXGLView+Texture.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import "WXGLView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WXGLView (Texture)

// 渲染2d纹理
- (void)drawImageWithProgram:(GLuint)program;

// 渲染相机rgb数据
- (void)renderWithRGBData:(char*)RGBData width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
