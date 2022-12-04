//
//  WXOpenGLDefine.h
//  OpenGLTutorials
//
//  Created by Rodin on 2022/8/14.
//

#ifndef WXOpenGLDefine_h
#define WXOpenGLDefine_h

#import <UIKit/UIKit.h>
#import <OpenGLES/gltypes.h>

#define STRINGIZE(x) #x
#define SHADER_STRING(text) @ STRINGIZE(text)


@protocol WXRenderProtocol <NSObject>

- (void)setupExtraEnv:(GLint)program;

- (void)renderWithContext:(EAGLContext *)context;

@end

#endif /* WXOpenGLDefine_h */
