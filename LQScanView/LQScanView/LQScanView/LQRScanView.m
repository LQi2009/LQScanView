//
//  LQScanView.m
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/15.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import "LQRScanView.h"
#import <AVFoundation/AVFoundation.h>
//#import <Vision/Vision.h>

BOOL isiPad() {
    NSString *model = [UIDevice currentDevice].model;
    if ([model isEqualToString:@"iPad"]) {
        return YES;
    }
    
    return NO;
}

@interface LQRScanView ()<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    NSInteger __scanCount;
    AVCaptureVideoPreviewLayer * __previewLayer ;
    AVCaptureMetadataOutput * __captureOutput ;
    AVCaptureDeviceInput * __deviceInput;
    UIInterfaceOrientation __currentOrientation;
    BOOL __isFullScreenScan;
    BOOL __isAnimating;
}

@property (nonatomic, strong) UIImageView * scanLine ;
@property (nonatomic, strong) UIView * overlayView ;
@property (nonatomic, strong) UILabel * textLabel ;
@property (nonatomic, strong) UIImageView * scanImageView ;
@property (nonatomic, strong) UIActivityIndicatorView * activity ;
@property (nonatomic, strong) AVCaptureSession *session;
//@property (nonatomic, strong) VNSequenceRequestHandler * reqHandler ;
@end

@implementation LQRScanView
//- (VNSequenceRequestHandler *)reqHandler {
//    if (_reqHandler == nil) {
//        _reqHandler = [[VNSequenceRequestHandler alloc]init];
//
//    }
//
//    return _reqHandler;
//}
- (void)dealloc {
    
    [self stopScanning];
    [self removeObservers];
    self.session = nil;
    NSLog(@"LQScanView dealloc");
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepare];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self prepare];
    }
    return self;
}

- (void) startScanning {

    [self.activity startAnimating];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        if (self.session.isRunning == NO) {
            NSLog(@"startRunning");
            [self.session startRunning];
            NSLog(@"**************************\n %@ \n **********************",NSStringFromCGRect([self->__previewLayer metadataOutputRectOfInterestForRect:self.scanArea]));
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.activity stopAnimating];
        });
    });
}

- (void) stopScanning {
    
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void) startAnimate {
    if (__isAnimating) {
        return;
    }
    __isAnimating = YES;
    self.scanLine.hidden = NO;
    
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationMove setFromValue:[NSNumber numberWithFloat:4]];
    [animationMove setToValue:[NSNumber numberWithFloat:CGRectGetHeight(self.scanArea) - 8]];
    animationMove.duration = 2;
    animationMove.repeatCount  = MAXFLOAT;
    animationMove.fillMode = kCAFillModeForwards;
    animationMove.removedOnCompletion = NO;
    animationMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [self.scanLine.layer addAnimation:animationMove forKey:@"lineMove"];
}

- (void) stopAnimate {
    if (__isAnimating == NO) {
        return;
    }
    __isAnimating = NO;
    [self.scanLine.layer removeAllAnimations];
    self.scanLine.hidden = YES;
}

- (void) autoFocusScanCenter {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error ;
        if ([device lockForConfiguration:&error]) {
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            if (device.focusPointOfInterestSupported) {
                CGFloat x = CGRectGetMinX(__captureOutput.rectOfInterest);
                CGFloat y = CGRectGetMinY(__captureOutput.rectOfInterest);
                device.focusPointOfInterest = CGPointMake(x, y);
            }
        }

        [device unlockForConfiguration];
    }
}
#pragma mark -
+ (void)turnTorch:(BOOL) on {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if ([device hasTorch] && [device hasFlash]){

            [device lockForConfiguration:nil];
            if (on) {

//                [device setTorchMode:AVCaptureTorchModeOn];
                if (@available(iOS 10.0, *)) {
                    AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
                    set.flashMode = AVCaptureFlashModeOn;
                } else {
                    // Fallback on earlier versions
                    [device setFlashMode:AVCaptureFlashModeOn];
                }
            } else {
//                [device setTorchMode:AVCaptureTorchModeOff];

                if (@available(iOS 10.0, *)) {
                    AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
                    set.flashMode = AVCaptureFlashModeOff;
                } else {
                    // Fallback on earlier versions
                    [device setFlashMode:AVCaptureFlashModeOff];
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

#pragma mark -
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
        [self stopScanning];
    } else if (noti.name == UIApplicationWillEnterForegroundNotification) {
        [self startScanning];
    } else if (noti.name == AVCaptureInputPortFormatDescriptionDidChangeNotification) {
        //设置有效扫描区域
        __captureOutput.rectOfInterest = [__previewLayer metadataOutputRectOfInterestForRect:self.scanArea];
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

                    [self startAnimate];
                }else{
                    [self stopAnimate];
                }
            }

        }
    });
}
#pragma mark -
- (void) prepare {
    
    self.backgroundColor = [UIColor blackColor];
    _maxScanCount = 0;
    _scanframeType = LQRScanframeTypeOn;
    _warnTextAlignment = LQRWarnTextAlignmentBottom;
    _warnText = @"将二维码放入框内，即可自动扫描";
    _scanlineName = @"reader_scan_scanline";
    _scanframeName = @"reader_scan_scanCamera";
    __isFullScreenScan = NO;
    
    CGRect f = [UIScreen mainScreen].bounds;
    CGFloat w = f.size.width < f.size.height ? f.size.width: f.size.height;
    w *= 0.7;
    if (w > 300) {
        w = 300;
    }
    
    CGFloat x = (CGRectGetWidth(f) - w) / 2.0;
    CGFloat y = (CGRectGetHeight(f) - w) / 2.0;
    self.scanArea = CGRectMake(x, y, w, w);
    
    [self prepareSession];
    [self addObservers];
}

- (void) prepareSession {
    if (self.session) {
        return;
    }
    
    if ([LQRScanView isCameraEnable] == NO) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scanViewCamaraDisable:)]) {
            [self.delegate scanViewCamaraDisable:self];
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
    __captureOutput = output;
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
    // 先将 output 添加到 session , 才能获取到有效的数据类型
    //        output.metadataObjectTypes = output.availableMetadataObjectTypes;
    
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    layer.videoGravity = AVLayerVideoGravityResizeAspect;
//    layer.videoGravity = AVLayerVideoGravityResize;
    [self.layer insertSublayer:layer atIndex:0];
    __previewLayer = layer;
    
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
    __previewLayer.connection.videoOrientation = o;
    
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    
    UIBezierPath *centerPath = [UIBezierPath bezierPathWithRect:self.scanArea];
    [path appendPath:centerPath];
    
    CAShapeLayer *overlay = [CAShapeLayer layer];
    overlay.path = path.CGPath;
    overlay.fillRule = kCAFillRuleEvenOdd;
    self.overlayView.layer.mask = overlay;
    
    [self startScanning];
    [self startAnimate];
    if (__isFullScreenScan) {
        __captureOutput.rectOfInterest = CGRectMake(0, 0, 1, 1);
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(scanView:lightChanged:)]) {
        [self.delegate scanView:self lightChanged:brightnessValue];
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(scanView:didScanned:)]) {
            
            [self.delegate scanView:self didScanned:results];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(scanViewScanFailed:)]) {
            
            [self.delegate scanViewScanFailed:self];
        }
    }
    
}

// 横竖屏切换时, 重置扫描区域
- (void) resetScanArea {
    
    if (CGRectEqualToRect(self.scanArea, CGRectZero)) {
        
        CGRect f = self.bounds;
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
            [self stopAnimate];
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

#pragma mark -
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.overlayView.frame = self.bounds;
    __previewLayer.frame = self.bounds;
    
    [self resetScanArea];
    
    if (self.warnTextAlignment == LQRWarnTextAlignmentTop) {
        self.textLabel.frame = CGRectMake(20, CGRectGetMinY(self.scanArea) - 40, CGRectGetWidth(self.bounds) - 40, 30);
    } else if (self.warnTextAlignment == LQRWarnTextAlignmentCenter) {
        self.textLabel.frame = CGRectMake(20, CGRectGetMidY(self.scanArea), CGRectGetWidth(self.bounds) - 40, 30);
    } else {
        self.textLabel.frame = CGRectMake(20, CGRectGetMaxY(self.scanArea) + 10, CGRectGetWidth(self.bounds) - 40, 30);
    }
    
    UIInterfaceOrientation ori = [UIApplication sharedApplication].statusBarOrientation;
    if (ori != UIInterfaceOrientationPortrait && ori != UIInterfaceOrientationPortraitUpsideDown) {
        
        if (CGRectGetMaxY(self.textLabel.frame) > CGRectGetHeight(self.frame)) {
            self.textLabel.frame = CGRectMake(20, CGRectGetMidY(self.scanArea), CGRectGetWidth(self.bounds) - 40, 30);
        }
    }
    
    if (self.scanframeType == LQRScanframeTypeOn) {
        self.scanImageView.frame = self.scanArea;
    } else if (self.scanframeType == LQRScanframeTypeOut) {
        
        self.scanImageView.frame = CGRectInset(self.scanArea, -4, -4);
    } else {
        self.scanImageView.frame = CGRectInset(self.scanArea, 2, 2);
    }
    
    self.scanLine.bounds = CGRectMake(0, 0, self.scanArea.size.width - 4, 2);
    self.scanLine.center = CGPointMake(CGRectGetMidX(self.scanArea), self.scanArea.origin.y + 4);
    self.activity.center = CGPointMake(CGRectGetMidX(self.scanArea), CGRectGetMidY(self.scanArea));
    
    [self resetSession];
}

- (UIImageView *)scanLine {
    if (_scanLine == nil) {
        _scanLine = [[UIImageView alloc]initWithImage:[UIImage imageNamed:self.scanlineName]];
        [self addSubview:_scanLine];
    }
    
    return _scanLine;
}

- (UIImageView *)scanImageView {
    if (_scanImageView == nil) {
        UIImage *img = [UIImage imageNamed:self.scanframeName];
        img = [img stretchableImageWithLeftCapWidth:img.size.width/2.0 topCapHeight:img.size.height/2.0];
        
        _scanImageView = [[UIImageView alloc]initWithImage:img];
        
        [self addSubview:_scanImageView];
    }
    return _scanImageView;
}

- (UILabel *)textLabel {
    if (_textLabel == nil) {
        _textLabel = [[UILabel alloc]init];
        _textLabel.text = self.warnText;
        _textLabel.font = [UIFont systemFontOfSize:14];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        [self addSubview:_textLabel];
    }
    
    return _textLabel;
}

- (UIActivityIndicatorView *)activity {
    if (_activity == nil) {
        _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhite)];
        [self addSubview:_activity];
    }
    
    return _activity;
}

- (UIView *)overlayView {
    if (_overlayView == nil) {
        
        _overlayView = [[UIView alloc]init];
        _overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        [self addSubview:_overlayView];
    }
    
    return _overlayView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


#pragma mark - 转换有效扫描区域坐标
- (void) configInterest {
//    [self coverInterest];
//    return;
    
    
    UIInterfaceOrientation deviceOr = [UIApplication sharedApplication].statusBarOrientation;
    CGRect r = CGRectZero;
    if (deviceOr == UIInterfaceOrientationPortrait) {
        r = [self configInterestPortaitOfCropRect:self.scanArea previewLayer:__previewLayer sessionPreset:self.session.sessionPreset output:__captureOutput];
    } else if (deviceOr == UIInterfaceOrientationLandscapeRight) {
        r = [self configInterestLandscapeRightOfCropRect:self.scanArea previewLayer:__previewLayer sessionPreset:self.session.sessionPreset output:__captureOutput];
    } else if (deviceOr == UIInterfaceOrientationLandscapeLeft) {
        r = [self configInterestLandscapeLeftOfCropRect:self.scanArea previewLayer:__previewLayer sessionPreset:self.session.sessionPreset output:__captureOutput];
    } else if (deviceOr == UIInterfaceOrientationPortraitUpsideDown) {
        r = [self configInterestPortaitUpsideDownOfCropRect:self.scanArea previewLayer:__previewLayer sessionPreset:self.session.sessionPreset output:__captureOutput];
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

// https://www.jianshu.com/p/8bb3d8cb224e
- (void) coverInterest {
    
    CGRect cropRect = self.scanArea;
    CGSize size = __previewLayer.bounds.size;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 0.0;
    
    if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        p2 = 1920./1080.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {
        p2 = 352./288.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        p2 = 1280./720.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        p2 = 960./540.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame1280x720]) {
        p2 = 1280./720.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetHigh]) {
        p2 = 1920./1080.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        p2 = 480./360.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetLow]) {
        p2 = 192./144.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) { // 暂时未查到具体分辨率，但是可以推导出分辨率的比例为4/3
        p2 = 4./3.;
    }
    else if ([_session.sessionPreset isEqualToString:AVCaptureSessionPresetInputPriority]) {
        p2 = 1920./1080.;
    }
    else if (@available(iOS 9.0, *)) {
        if ([_session.sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]) {
            p2 = 3840./2160.;
        }
    } else {
        
    }
    if ([__previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        __captureOutput.rectOfInterest = CGRectMake((cropRect.origin.y)/size.height,(size.width-(cropRect.size.width+cropRect.origin.x))/size.width, cropRect.size.height/size.height,cropRect.size.width/size.width);
    } else if ([__previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (p1 < p2) {
            CGFloat fixHeight = size.width * p2;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            __captureOutput.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x))/size.width,
                                                        cropRect.size.height/fixHeight,
                                                        cropRect.size.width/size.width);
        } else {
            CGFloat fixWidth = size.height * (1/p2);
            CGFloat fixPadding = (fixWidth - size.width)/2;
            __captureOutput.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x)+fixPadding)/fixWidth,
                                                        cropRect.size.height/size.height,
                                                        cropRect.size.width/fixWidth);
        }
    } else if ([__previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (p1 > p2) {
            CGFloat fixHeight = size.width * p2;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            __captureOutput.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x))/size.width,
                                                        cropRect.size.height/fixHeight,
                                                        cropRect.size.width/size.width);
        } else {
            CGFloat fixWidth = size.height * (1/p2);
            CGFloat fixPadding = (fixWidth - size.width)/2;
            __captureOutput.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                        (size.width-(cropRect.size.width+cropRect.origin.x)+fixPadding)/fixWidth,
                                                        cropRect.size.height/size.height,
                                                        cropRect.size.width/fixWidth);
        }
    }
}
@end


@implementation LQRScanResult
@end
