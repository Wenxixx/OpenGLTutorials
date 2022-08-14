//
//  WXGLView.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    GLShaderTypeNormal,
    GLShaderTypeTexture
} GLShaderType;


@interface WXGLView : UIView

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLShaderType shaderType;

//@property (nonatomic, strong) dispatch_queue_t renderQueue;

@end

NS_ASSUME_NONNULL_END
