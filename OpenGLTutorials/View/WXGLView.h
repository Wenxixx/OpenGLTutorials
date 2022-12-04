//
//  WXGLView.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXGLView : UIView

// 渲染相机rgb格式数据
- (void)renderWithCameraRgbData:(char*)rgbData width:(int)width height:(int)height;

// 渲染相机YUV格式数据
- (void)renderWithYData:(char*)YData UVData:(char*)UVData width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
