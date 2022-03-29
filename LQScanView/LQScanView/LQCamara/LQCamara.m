//
//  LQCamara.m
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/29.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import "LQCamara.h"
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>

@interface LQCamara () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureStillImageOutput *__stillImageOutput;
    AVCaptureDeviceInput * __deviceInput;
    
API_AVAILABLE(ios(10.0))
    AVCapturePhotoOutput * __photo;
}

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer ;
@property (nonatomic, strong) VNSequenceRequestHandler * reqHandler ;
@end
@implementation LQCamara
- (VNSequenceRequestHandler *)reqHandler {
    if (_reqHandler == nil) {
        _reqHandler = [[VNSequenceRequestHandler alloc]init];
        
    }
    
    return _reqHandler;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void) prapareSession {
    
    if (self.session) {
        return;
    }
    
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    // 设置自动对焦
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [device lockForConfiguration:nil];
        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [device unlockForConfiguration];
    }
    
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer insertSublayer:layer atIndex:0];
    self.previewLayer = layer;
    
    if (@available(iOS 10.0, *)) {
        AVCapturePhotoOutput *po = [[AVCapturePhotoOutput alloc]init];
    } else {
        // Fallback on earlier versions
        AVCaptureStillImageOutput * o = [[AVCaptureStillImageOutput alloc]init];
        if (@available(iOS 11.0, *)) {
            o.outputSettings = @{AVVideoCodecKey: AVVideoCodecTypeJPEG};
        } else {
            // Fallback on earlier versions
            o.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
        }
        if ([self.session canAddOutput:o]) {
            //        [o ];
            [self.session addOutput:o];
        }
        __stillImageOutput = o;
    }
    
    
}

+ (BOOL)isCameraEnable {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        
        return NO;
    } else {
        
        return YES;
    }
}

- (void) photoButtonAction {
    AVCaptureConnection *connection = [__stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation videoOri = AVCaptureVideoOrientationPortrait;
    
    UIInterfaceOrientation ori = [UIApplication sharedApplication].statusBarOrientation;
    if (ori == UIInterfaceOrientationPortrait) {
        videoOri = AVCaptureVideoOrientationPortrait;
    } else if (ori == UIInterfaceOrientationLandscapeLeft) {
        videoOri = AVCaptureVideoOrientationLandscapeLeft;
    } else if (ori == UIInterfaceOrientationLandscapeRight) {
        videoOri = AVCaptureVideoOrientationLandscapeRight ;
    } else if (ori == UIInterfaceOrientationPortraitUpsideDown) {
        videoOri = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    
    connection.videoOrientation = videoOri;
    connection.videoScaleAndCropFactor = 1.;
    [__stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        //        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
        //                                                                    imageDataSampleBuffer,
        //                                                                    kCMAttachmentMode_ShouldPropagate);
        
        UIImage *img = [UIImage imageWithData:jpegData];
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    }];
    
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    
    
    CVImageBufferRef buff = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    VNDetectBarcodesRequest *req = [[VNDetectBarcodesRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        for (VNBarcodeObservation *obs in request.results) {
            
            NSLog(@"%@---%@", NSStringFromCGRect(obs.boundingBox), obs.payloadStringValue);
        }
    }];
    [self.reqHandler performRequests:@[req] onCVPixelBuffer:buff error:nil];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
