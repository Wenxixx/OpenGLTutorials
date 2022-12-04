//
//  Tutorials_002_Texture.h
//  OpenGLTutorials
//
//  Created by Steven Deng on 2022/12/3.
//

#import <Foundation/Foundation.h>
#import "WXOpenGLDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface Tutorials_002_Texture : NSObject<WXRenderProtocol>

- (void)renderWithContext:(EAGLContext *)context rgbData:(char*)rgbData width:(int)width height:(int)height;

- (void)renderWithContext:(EAGLContext *)context YData:(char*)YData UVData:(char*)UVData width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
