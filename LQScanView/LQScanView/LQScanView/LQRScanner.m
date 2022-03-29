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
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidStartScanning:)]) {
                    [self.delegate scannerDidStartScanning:self];
                }
            });
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
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observerSelectors:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //    @"enterBackground"
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observerSelectors:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
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
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerIsScanning:)]) {
                        [self.delegate scannerIsScanning:self];
                    }
                }else{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(scannerStopScanning:)]) {
                        [self.delegate scannerStopScanning:self];
                    }
                }
            }
            
        }
    });
}


+ (BOOL)isiPad {
    NSString *model = [UIDevice currentDevice].model;
    if ([model isEqualToString:@"iPad"]) {
        return YES;
    }
    
    return NO;
}
@end
