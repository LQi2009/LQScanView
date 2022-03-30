//
//  LQRScanner.m
//  LQScanView
//
//  Created by 刘启强 on 2022/3/29.
//  Copyright © 2022 Q.ice. All rights reserved.
//

#import "LQRScanner.h"
#import <AVFoundation/AVFoundation.h>


@interface LQRScanner ()<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
    NSInteger __scanCount;
    UIInterfaceOrientation __currentOrientation;
    BOOL __isFullScreenScan;
    BOOL __isAnimating;
}

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *captureOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@end
@implementation LQRScanner


- (void) startScanning {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerWillStartScanning:)]) {
        [self.delegate scannerWillStartScanning:self];
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        if (self.session.isRunning == NO) {
            
            [self.session startRunning];
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidStartScanning:)]) {
//                    [self.delegate scannerDidStartScanning:self];
//                }
//            });
        }
    });
}

- (void) stopScanning {
    
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void) autoFocusScanCenter {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error ;
        if ([device lockForConfiguration:&error]) {
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            if (device.focusPointOfInterestSupported) {
                CGFloat x = CGRectGetMinX(self.captureOutput.rectOfInterest);
                CGFloat y = CGRectGetMinY(self.captureOutput.rectOfInterest);
                device.focusPointOfInterest = CGPointMake(x, y);
            }
        }
        
        [device unlockForConfiguration];
    }
}

+ (void)turnTorch:(BOOL) on {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                
                if (@available(iOS 10.0, *)) {
                    AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
                    set.flashMode = AVCaptureFlashModeOn;
                } else {
                    // Fallback on earlier versions
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                    [device setFlashMode:AVCaptureFlashModeOn];
#pragma clang diagnostic pop
                }
            } else {
//                [device setTorchMode:AVCaptureTorchModeOff];

                if (@available(iOS 10.0, *)) {
                    AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
                    set.flashMode = AVCaptureFlashModeOff;
                } else {
                    // Fallback on earlier versions
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                    [device setFlashMode:AVCaptureFlashModeOff];
#pragma clang diagnostic pop
                }
            }
            [device unlockForConfiguration];
        }
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

#pragma mark - Observers & Actions
- (void) addObservers {
    //使用通知监听app进入后台
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observerSelectors:) name:UIApplicationDidEnterBackgroundNotification object:nil];
//    //    @"enterBackground"
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observerSelectors:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observerSelectors:) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    
    
    //UIApplicationWillChangeStatusBarFrameNotification 将要转屏
    //UIApplicationDidChangeStatusBarFrameNotification 已经转屏
    // 转屏通知
    //    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didChangeRotate:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void) removeObservers {
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self.session removeObserver:self forKeyPath:@"running"];
}

- (void) observerSelectors:(NSNotification *) noti {
    if (noti.name == UIApplicationDidEnterBackgroundNotification) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidEnterBackground:)]) {
            [self.delegate scannerDidEnterBackground:self];
        }
    } else if (noti.name == UIApplicationWillEnterForegroundNotification) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scannerWillEnterForeground:)]) {
            [self.delegate scannerWillEnterForeground:self];
        }
    } else if (noti.name == AVCaptureInputPortFormatDescriptionDidChangeNotification) {
        //设置有效扫描区域
        self.captureOutput.rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:self.scanArea];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([object isKindOfClass:[AVCaptureSession class]]) {
            
            if ([keyPath isEqualToString:@"running"]) {
                BOOL isRunning = ((AVCaptureSession *)object).isRunning;
                if (isRunning) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidStartScanning:)]) {
                            [self.delegate scannerDidStartScanning:self];
                        }
                    });
                }else{
//                    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerStopScanning:)]) {
//                        [self.delegate scannerStopScanning:self];
//                    }
                }
            }
            
        }
    });
}

- (void) prepareSession {
    if (self.session) {
        return;
    }
    
    if ([LQRScanner isCameraEnable] == NO) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scannerCamaraDisable:)]) {
            [self.delegate scannerCamaraDisable:self];
        }
        return;
    }
    
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    // 设置自动对焦
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSLog(@"lockForConfiguration");
        [device lockForConfiguration:nil];
        
        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [device unlockForConfiguration];
        NSLog(@"unlockForConfiguration");
    }
    
    self.session = [[AVCaptureSession alloc]init];
//    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
        [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    self.captureOutput = output;
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    if ([self.session canAddOutput:output]) {
        
        [self.session addOutput:output];
    }
    //设置扫码支持的编码格式
    NSMutableArray *a = [[NSMutableArray alloc] init];
    
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        [a addObject:AVMetadataObjectTypeQRCode];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
        [a addObject:AVMetadataObjectTypeEAN13Code];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
        [a addObject:AVMetadataObjectTypeEAN8Code];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
        [a addObject:AVMetadataObjectTypeCode128Code];
    }
    
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode39Code]) {
        [a addObject:AVMetadataObjectTypeCode39Code];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode39Mod43Code]) {
        [a addObject:AVMetadataObjectTypeCode39Mod43Code];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode93Code]) {
        [a addObject:AVMetadataObjectTypeCode93Code];
    }
    
    output.metadataObjectTypes = a;
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    layer.videoGravity = AVLayerVideoGravityResizeAspect;
//    layer.videoGravity = AVLayerVideoGravityResize;
    [self.view.layer insertSublayer:layer atIndex:0];
    self.previewLayer = layer;
    
    if (self.lightDetectionEnable) {
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        
        if ([self.session canAddOutput:output]) {
            [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
            [self.session addOutput:output];
        }
    }
}

- (void)setLightDetectionEnable:(BOOL)lightDetectionEnable {
    _lightDetectionEnable = lightDetectionEnable;
    
    if (lightDetectionEnable) {
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
        if ([self.session canAddOutput:output]) {
            [self.session addOutput:output];
        }
    } else {
        NSArray *outputs = self.session.outputs;
        for (AVCaptureOutput *output in outputs) {
            if ([output isKindOfClass:[AVCaptureVideoDataOutput class]]) {
                AVCaptureVideoDataOutput *o = (AVCaptureVideoDataOutput*)output;
                [o setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
                [self.session removeOutput:output];
                break;
            }
        }
    }
}

- (void) resetSession {
    
    UIInterfaceOrientation deviceOri = [UIApplication sharedApplication].statusBarOrientation;
    
    if (__currentOrientation == deviceOri) {
        return;
    }
    
    __currentOrientation = deviceOri;
    
    AVCaptureVideoOrientation o = AVCaptureVideoOrientationPortrait;
    if (deviceOri == UIInterfaceOrientationPortrait) {
        o = AVCaptureVideoOrientationPortrait;
    } else if (deviceOri == UIInterfaceOrientationPortraitUpsideDown) {
        o = AVCaptureVideoOrientationPortraitUpsideDown;
    } else if (deviceOri == UIInterfaceOrientationLandscapeLeft) {
        o = AVCaptureVideoOrientationLandscapeLeft ;
    } else if (deviceOri == UIInterfaceOrientationLandscapeRight) {
        o = AVCaptureVideoOrientationLandscapeRight ;
    }
    self.previewLayer.connection.videoOrientation = o;
    
    [self startScanning];

    if (__isFullScreenScan) {
        self.captureOutput.rectOfInterest = CGRectMake(0, 0, 1, 1);
    } else {
        [self configInterest];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(scanner:lightChanged:)]) {
        [self.delegate scanner:self lightChanged:brightnessValue];
    }
    
//    CVImageBufferRef buff = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//    VNDetectBarcodesRequest *req = [[VNDetectBarcodesRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
//
//        for (VNBarcodeObservation *obs in request.results) {
//
//            NSLog(@"%@---%@", NSStringFromCGRect(obs.boundingBox), obs.payloadStringValue);
//        }
//    }];
//    [self.reqHandler performRequests:@[req] onCVPixelBuffer:buff error:nil];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    NSLog(@"Result: %@", metadataObjects);
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:metadataObjects.count];
    if (metadataObjects.count > 0) {
        
        for (AVMetadataMachineReadableCodeObject *obj in metadataObjects) {
            LQRScanResult *res = [[LQRScanResult alloc]init];
            res.result = obj.stringValue;
            [results addObject:res];
        }
        
    } else {
        if (self.maxScanCount > 0) {
            __scanCount ++;
            if (__scanCount < self.maxScanCount) {
                return;
            }
        }
    }
    
    __scanCount = 0;
    [self stopScanning];
    if (results.count > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scanner:didScanned:)]) {
            
            [self.delegate scanner:self didScanned:results];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scannerScanFailed:)]) {
            
            [self.delegate scannerScanFailed:self];
        }
    }
    
}

- (void) resetScanArea {
    
    if (CGRectEqualToRect(self.scanArea, CGRectZero)) {
        
        CGRect f = self.frame;
        CGFloat w = f.size.width < f.size.height ? f.size.width: f.size.height;
        w *= 0.7;
        if (w > 300) {
            w = 300;
        }
        
        CGFloat x = (CGRectGetWidth(f) - w) / 2.0;
        CGFloat y = (CGRectGetHeight(f) - w) / 2.0;
        self.scanArea = CGRectMake(x, y, w, w);
        __isFullScreenScan = YES;
    } else {
        
        UIInterfaceOrientation deviceOri = [UIApplication sharedApplication].statusBarOrientation;
        if (__currentOrientation != deviceOri) {
            
            CGRect r = self.scanArea;
            if (__currentOrientation == UIInterfaceOrientationPortrait) {
                
                if (deviceOri == UIInterfaceOrientationLandscapeLeft) {
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxY(self.scanArea);
                    r.origin.y = CGRectGetMinX(self.scanArea);
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationLandscapeRight) {
                    r.origin.x = self.scanArea.origin.y;
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationPortraitUpsideDown) {
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxY(self.scanArea);
                }
            } else if (__currentOrientation == UIInterfaceOrientationLandscapeRight) {
                if (deviceOri == UIInterfaceOrientationPortrait) {
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxY(self.scanArea);
                    r.origin.y = self.scanArea.origin.x;
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationPortraitUpsideDown) {
                    r.origin.y = CGRectGetHeight(self.scanArea) - CGRectGetMaxX(self.scanArea);
                    r.origin.x = self.scanArea.origin.y;
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationLandscapeLeft) {
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxY(self.scanArea);
                }
            } else if (__currentOrientation == UIInterfaceOrientationLandscapeLeft) {
                if (deviceOri == UIInterfaceOrientationPortrait) {
                    r.origin.x = CGRectGetMinY(self.scanArea);
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationLandscapeRight) {
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxY(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationPortraitUpsideDown) {
                    r.origin.y = CGRectGetMinX(self.scanArea);
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxY(self.scanArea);
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                }
            } else if (__currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
                if (deviceOri == UIInterfaceOrientationPortrait) {
                    r.origin.x = CGRectGetWidth(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxY(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationLandscapeLeft) {
                    r.origin.x = CGRectGetMinY(self.scanArea);
                    r.origin.y = CGRectGetHeight(self.frame) - CGRectGetMaxX(self.scanArea);
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                } else if (deviceOri == UIInterfaceOrientationLandscapeRight) {
                    r.origin.x = CGRectGetHeight(self.frame) - CGRectGetMaxY(self.scanArea);
                    r.origin.y = CGRectGetMinX(self.scanArea);
                    r.size.width = CGRectGetHeight(self.scanArea);
                    r.size.height = CGRectGetWidth(self.scanArea);
                }
            }
            
            self.scanArea = r;
        }
    }
}

#pragma mark - 转换有效扫描区域坐标
- (void) configInterest {
//    [self coverInterest];
//    return;
    
    
    UIInterfaceOrientation deviceOr = [UIApplication sharedApplication].statusBarOrientation;
    CGRect r = CGRectZero;
    if (deviceOr == UIInterfaceOrientationPortrait) {
        r = [self configInterestPortaitOfCropRect:self.scanArea previewLayer:self.previewLayer sessionPreset:self.session.sessionPreset output:self.captureOutput];
    } else if (deviceOr == UIInterfaceOrientationLandscapeRight) {
        r = [self configInterestLandscapeRightOfCropRect:self.scanArea previewLayer:self.previewLayer sessionPreset:self.session.sessionPreset output:self.captureOutput];
    } else if (deviceOr == UIInterfaceOrientationLandscapeLeft) {
        r = [self configInterestLandscapeLeftOfCropRect:self.scanArea previewLayer:self.previewLayer sessionPreset:self.session.sessionPreset output:self.captureOutput];
    } else if (deviceOr == UIInterfaceOrientationPortraitUpsideDown) {
        r = [self configInterestPortaitUpsideDownOfCropRect:self.scanArea previewLayer:self.previewLayer sessionPreset:self.session.sessionPreset output:self.captureOutput];
    }
    
    NSLog(@"==========================\n %@ \n ===================", NSStringFromCGRect(r));
}

/**
横屏有效扫描区域, Home 在左侧

 @return 有效扫描区域
 */
- (CGRect) configInterestLandscapeLeftOfCropRect:(CGRect) cropRect
                                    previewLayer:(AVCaptureVideoPreviewLayer *) previewLayer
                                   sessionPreset:(AVCaptureSessionPreset)sessionPreset
                                          output:(AVCaptureMetadataOutput*)output {
    
    CGSize size = previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1080./1920.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1080./1920.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        p2 = 640./852.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1080./1920.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 2160./3840.;
        }
    } else {
        
    }
    
    CGRect r = CGRectMake(0, 0, 1., 1.);
    
    
    if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        r.origin.x = (size.width - CGRectGetMaxX(cropRect))/size.width;
        r.origin.y = (size.height - CGRectGetMaxY(cropRect))/size.height;
        r.size.width = cropRect.size.width/size.width ;
        r.size.height = cropRect.size.height/size.height ;
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        
        if (p1 > p2) {
            CGFloat width = size.height / p2;
            CGFloat padding = (width - size.width)/2;
            
            r.origin.x = (size.width - CGRectGetMaxX(cropRect) + padding)/width ;
            r.origin.y = (size.height - CGRectGetMaxY(cropRect))/size.height ;
            r.size.width = cropRect.size.width/width ;
            r.size.height = cropRect.size.height/size.height ;
        } else {
            
            CGFloat height = size.width * p2;
            CGFloat padding = (height - size.height) / 2.0;
            
            r.origin.x = (size.width - CGRectGetMaxX(cropRect))/size.width;
            r.origin.y = (size.height - CGRectGetMaxY(cropRect) + padding)/height;
            r.size.width = cropRect.size.width/size.width ;
            r.size.height = cropRect.size.height/height ;
        }
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {

            CGFloat height = size.width * p2;
            CGFloat padding = (size.height - height)/2;
            
            r.origin.x = (size.width - CGRectGetMaxX(cropRect))/size.width ;
            r.origin.y = (size.height - CGRectGetMaxY(cropRect) - padding)/height ;
            r.size.width =  cropRect.size.width/size.width ;
            r.size.height = cropRect.size.height/height ;
        } else {
            CGFloat width = size.height / p2;
            CGFloat padding = (size.width - width)/2.;
            
            r.origin.x = (size.width - CGRectGetMaxX(cropRect) - padding)/width ;
            r.origin.y =  (size.height - CGRectGetMaxY(cropRect))/size.height ;
            r.size.width = cropRect.size.width/width ;
            r.size.height = cropRect.size.height/size.height ;
        }
    }
    
    output.rectOfInterest = r;
    return r;
}


/**
 横屏下的有效扫描区域, Home键在右侧

 @return 有效扫描区域
 */
- (CGRect) configInterestLandscapeRightOfCropRect:(CGRect) cropRect
                                     previewLayer:(AVCaptureVideoPreviewLayer *) previewLayer
                                    sessionPreset:(AVCaptureSessionPreset)sessionPreset
                                           output:(AVCaptureMetadataOutput*)output {
    
    CGSize size = previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1080./1920.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1080./1920.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        p2 = 640./852.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1080./1920.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 2160./3840.;
        }
    }
    
    CGRect r = CGRectMake(0, 0, 1., 1.);
    
    if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        r.origin.x = (CGRectGetMinX(cropRect))/size.width;
        r.origin.y = (CGRectGetMinY(cropRect))/size.height;
        r.size.width = cropRect.size.width/size.width ;
        r.size.height = cropRect.size.height/size.height;
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        
        if (p1 > p2) {
            CGFloat width = size.height / p2;
            CGFloat padding = (width - size.width) / 2.0;
            
            r.origin.x = (CGRectGetMinX(cropRect) + padding)/width ;
            r.origin.y = (CGRectGetMinY(cropRect))/size.height ;
            r.size.width = cropRect.size.width/width ;
            r.size.height = cropRect.size.height/size.height ;
        } else {
            CGFloat height = size .width * p2;
            CGFloat padding = (height  - size.height) / 2.0;
            
            r.origin.x = CGRectGetMinX(cropRect) / size.width;
            r.origin.y = (CGRectGetMinY(cropRect) + padding) / height;
            r.size.width = CGRectGetWidth(cropRect) / size.width;
            r.size.height = CGRectGetHeight(cropRect) / height;
        }
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {
            CGFloat height = size.width * p2;
            CGFloat padding = (size.height - height)/2.0;
            
            r.origin.x = CGRectGetMinX(cropRect)/size.width ;
            r.origin.y = (CGRectGetMinY(cropRect) - padding)/ height ;
            r.size.width = cropRect.size.width/size.width ;
            r.size.height =  cropRect.size.height/height ;
        } else {
            CGFloat width = size.height / p2;
            CGFloat padding = (size.width - width)/2.;
            
            r.origin.x = (CGRectGetMinX(cropRect) - padding)/width ;
            r.origin.y = (CGRectGetMinY(cropRect))/size.height ;
            r.size.width = cropRect.size.width/width ;
            r.size.height = cropRect.size.height/size.height ;
        }
    }
    
    output.rectOfInterest = r;
    return r;
}

/**
 竖屏时, 有效扫描区域计算

 @return 有效扫描区域
 */
- (CGRect) configInterestPortaitOfCropRect:(CGRect) cropRect
                              previewLayer:(AVCaptureVideoPreviewLayer *) previewLayer
                             sessionPreset:(AVCaptureSessionPreset)sessionPreset
                                    output:(AVCaptureMetadataOutput*)output {
    
    CGSize size = previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1920./1080.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1920./1080.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        p2 = 852./640.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1920./1080.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 3840./2160.;
        }
    } else {
        
    }
    
    CGRect r = CGRectMake(0, 0, 1., 1.);
    
    if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        
        r.origin.x = (cropRect.origin.y)/size.height;
        r.origin.y = (size.width - CGRectGetMaxX(cropRect))/size.width;
        r.size.width = cropRect.size.height/size.height;
        r.size.height = cropRect.size.width/size.width;
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        
        if (p1 < p2) {
            CGFloat height = size.width * p2;
            CGFloat padding = (height - size.height)/2.;
            
            r.origin.x = (CGRectGetMinY(cropRect) + padding)/height ;
            r.origin.y = (size.width - CGRectGetMaxX(cropRect))/size.width ;
            r.size.width = cropRect.size.height/height ;
            r.size.height = cropRect.size.width/size.width ;
        } else {
            CGFloat width = size.height / p2;
            CGFloat padding = (width - size.width)/2.;
            
            r.origin.x = CGRectGetMinY(cropRect)/size.height ;
            r.origin.y = (size.width - CGRectGetMaxX(cropRect) + padding)/width;
            r.size.width = cropRect.size.height/size.height ;
            r.size.height = cropRect.size.width/width ;
        }
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {
            CGFloat height = size.width * p2;
            CGFloat padding = (size.height - height)/2.0;
            
            r.origin.x = (CGRectGetMinY(cropRect) - padding)/height ;
            r.origin.y = (size.width - CGRectGetMaxX(cropRect))/size.width ;
            r.size.width = cropRect.size.height/height ;
            r.size.height = cropRect.size.width/size.width ;
        } else {
            CGFloat width = size.height * (1./p2);
            CGFloat padding = (size.width - width)/2;
            
            r.origin.x = CGRectGetMinY(cropRect)/size.height ;
            r.origin.y = (size.width - CGRectGetMaxX(cropRect) - padding)/width ;
            r.size.width = cropRect.size.height/size.height ;
            r.size.height = cropRect.size.width/width ;
        }
    }
    
    output.rectOfInterest = r;
    return r;
}

- (CGRect) configInterestPortaitUpsideDownOfCropRect:(CGRect) cropRect
                                        previewLayer:(AVCaptureVideoPreviewLayer *) previewLayer
                                       sessionPreset:(AVCaptureSessionPreset)sessionPreset
                                              output:(AVCaptureMetadataOutput*)output {
    
    CGSize size = previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1920./1080.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1920./1080.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        p2 = 852./640.;
    }
    else if ([sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1920./1080.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 3840./2160.;
        }
    } else {
        
    }
    
    CGRect r = CGRectMake(0, 0, 1., 1.);
    
    if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        
        r.origin.x = (size.height - CGRectGetMaxY(cropRect))/size.height;
        r.origin.y = (CGRectGetMinX(cropRect))/size.width;
        r.size.width = cropRect.size.height/size.height;
        r.size.height = cropRect.size.width/size.width;
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        
        if (p1 < p2) {
            CGFloat height = size.width * p2;
            CGFloat padding = (height - size.height)/2.;
            
            r.origin.x = (size.height - CGRectGetMaxY(cropRect) + padding)/height;
            r.origin.y = (CGRectGetMinX(cropRect))/size.width;
            r.size.width = cropRect.size.height/height;
            r.size.height = cropRect.size.width/size.width;
        } else {
            CGFloat width = size.height / p2;
            CGFloat padding = (width - size.width)/2.;
            
            r.origin.x = (size.height - CGRectGetMaxY(cropRect))/size.height;
            r.origin.y = (CGRectGetMinX(cropRect) + padding)/width;
            r.size.width = cropRect.size.height/size.height;
            r.size.height = cropRect.size.width/width;
        }
    } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {
            CGFloat height = size.width * p2;
            CGFloat padding = (size.height - height)/2.0;
            
            r.origin.x = (size.height - CGRectGetMaxY(cropRect) - padding)/height;
            r.origin.y = (CGRectGetMinX(cropRect))/size.width;
            r.size.width = cropRect.size.height/height;
            r.size.height = cropRect.size.width/size.width;
        } else {
            CGFloat width = size.height * (1./p2);
            CGFloat padding = (size.width - width)/2;
            
            r.origin.x = CGRectGetMinY(cropRect)/size.height ;
            r.origin.y = (CGRectGetMinX(cropRect) - padding)/width ;
            r.size.width = cropRect.size.height/size.height ;
            r.size.height = cropRect.size.width/width ;
        }
    }
    
    output.rectOfInterest = r;
    return r;
}

+ (BOOL)isiPad {
    NSString *model = [UIDevice currentDevice].model;
    if ([model isEqualToString:@"iPad"]) {
        return YES;
    }
    
    return NO;
}

- (UIView *)view
{
    if (!_view) {
        _view = [[UIView alloc] init];
        _view.autoresizesSubviews = YES;
        _view.backgroundColor = [UIColor clearColor];
    }
    return _view;
}
@end

@implementation LQRScanResult
@end
