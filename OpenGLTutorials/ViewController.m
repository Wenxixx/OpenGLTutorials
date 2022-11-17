//
//  ViewController.m
//  OpenGL
//
//  Created by Steven Deng on 2022/8/8.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WXNV12View.h"
#import "WXGLView.h"
#import "WXGLView+Texture.h"
#import "WXSampleBufferDisplayView.h"

typedef enum : NSUInteger {
    AVOutputTypeNV12,
    AVOutputTypeYUV,
    AVOutputTypeRGBA,
} AVOutputType;


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) IBOutlet UIView                     *previewView;
@property (nonatomic, weak) IBOutlet WXNV12View                 *renderView;
@property (nonatomic, weak) IBOutlet WXGLView                   *rgbRenderView;
@property (nonatomic, weak) IBOutlet WXSampleBufferDisplayView  *sampleBufferView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;

@property (nonatomic, assign) AVOutputType outputType;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置视频流格式
    self.outputType = AVOutputTypeRGBA;
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *frontCamera;
    for (AVCaptureDevice *device in cameras) {
        if (device.position == AVCaptureDevicePositionFront) {
            frontCamera = device;
            break;
        }
    }
    
    if (!frontCamera) {
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera
                                                                             error:&error];
    
    [self.session addInput:videoInput];
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *settings;
    if (self.outputType == AVOutputTypeRGBA) {
        settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                    [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                    kCVPixelBufferPixelFormatTypeKey,
                    nil];  // kCVPixelFormatType_32RGBA
    } else {
        settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                    [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
                    kCVPixelBufferPixelFormatTypeKey,
                    nil];
    }
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t queue = dispatch_queue_create("avCaptureQueue", NULL);
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    self.videoConnection = [avCaptureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.session addOutput:avCaptureVideoDataOutput];
    [self.session startRunning];
    
    AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewView.layer addSublayer:layer];
    layer.frame = self.previewView.bounds;
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
        if (self.outputType == AVOutputTypeNV12) {
            //图像宽度（像素）
            size_t pixelWidth = CVPixelBufferGetWidth(imageBuffer);
            //图像高度（像素）
            size_t pixelHeight = CVPixelBufferGetHeight(imageBuffer);
            //获取CVImageBufferRef中的y数据
            uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
            //获取CMVImageBufferRef中的uv数据
            uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
            if (self.renderView) {
                [self.renderView renderWithYData:(char*)y_frame
                                          UVData:(char*)uv_frame
                                           width:(int)pixelWidth
                                          height:(int)pixelHeight];
            }
            
            
            [self.sampleBufferView displayWithNV12yBuffer:y_frame
                                                 uvBuffer:uv_frame
                                                    width:(int)pixelWidth
                                                   height:(int)pixelHeight];
            
        } else if (self.outputType == AVOutputTypeYUV) {
            //图像宽度（像素）
            size_t pixelWidth = CVPixelBufferGetWidth(imageBuffer);
            //图像高度（像素）
            size_t pixelHeight = CVPixelBufferGetHeight(imageBuffer);
            //获取CVImageBufferRef中的y数据
            uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
            //获取CMVImageBufferRef中的uv数据
            uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
            
            [self.renderView renderWithYData:y_frame UVData:uv_frame width:(int)pixelWidth height:(int)pixelHeight];
        } else {
            uint8_t *rgbaData = CVPixelBufferGetBaseAddress(imageBuffer);
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);
            if (self.rgbRenderView) {
                [self.rgbRenderView renderWithRGBData:(char *)rgbaData
                                                width:(int)width
                                               height:(int)height];
            }
//            [self.sampleBufferView displayWithRGBBuffer:rgbaData
//                                                  width:(int)width
//                                                 height:(int)height];
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
}


@end
