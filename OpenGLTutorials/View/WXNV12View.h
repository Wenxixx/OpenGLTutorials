//
//  WXNV12View.h
//  OpenGL
//
//  Created by Steven Deng on 2022/8/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXNV12View : UIView

-(void)renderWithYData:(char*)YData UVData:(char*)UVData width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
