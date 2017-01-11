//
//  LZScanner.m
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import "LZScanner.h"
#import <AVFoundation/AVFoundation.h>

@interface LZScanner ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@end
@implementation LZScanner

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        if ([LZScanner isCameraEnable]) {
            
            if (frame.size.width > 0) {
                self.frame = frame;
            } else {
                self.frame = [[UIApplication sharedApplication] keyWindow].bounds;
            }
            
            [self creatSession];
        }
    }
    
    return self;
}
    
#pragma mark-> 开关闪光灯
+ (void)turnTorchOn:(BOOL)on
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                
                [device setTorchMode:AVCaptureTorchModeOn];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
                AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
                set.flashMode = AVCaptureFlashModeOn;
#else
                [device setFlashMode:AVCaptureFlashModeOn];
#endif
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
                AVCapturePhotoSettings *set = [AVCapturePhotoSettings photoSettings];
                set.flashMode = AVCaptureFlashModeOff;
                
#else
                [device setFlashMode:AVCaptureFlashModeOff];
#endif
            }
            [device unlockForConfiguration];
        }
    }
}

+ (void)scanImage:(UIImage*)image result:(void(^)(NSString *result))block {
    
    //2.初始化一个监测器
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    
    //监测到的结果数组
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    
    NSString *scanResult = nil;
    if(features.count >=1) {
        
        /**结果对象 */
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        scanResult = feature.messageString;
        
        
    } else {
        
        scanResult = @"无结果";
    }
    
    if (block) {
        
        block(scanResult);
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

- (void)startScanning {
    
    [self.session startRunning];
}

- (void)stopScanning {
    
    [self.session stopRunning];
}

- (BOOL)isScanning {
    
    return [self.session isRunning];
}

//初始化扫描流
- (void)creatSession {
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置有效扫描区域
    CGRect scanCrop=[self setScanCropWitnBounds:self.bounds];
    output.rectOfInterest = scanCrop;
    //初始化链接对象
    self.session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [self.session addInput:input];
    [self.session addOutput:output];
    
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.layer.bounds;
    [self.layer insertSublayer:layer atIndex:0];
    
    [self.session startRunning];
}

//获取扫描结果
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    [self stopScanning];
    NSString *result = nil;
    if (metadataObjects.count>0) {
        
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        
        result = metadataObject.stringValue;
        
    } else {
        
        result = @"无结果";
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(scanner:didScanned:)]) {
        
        [self.delegate scanner:self didScanned:result];
    }
}

- (void)setScanArea:(CGRect)scanArea {
    
    _scanArea = scanArea;
    
    AVCaptureMetadataOutput *output = [self.session.outputs firstObject];
    output.rectOfInterest = [self setScanCropWitnBounds:scanArea];
}
#pragma mark-> 获取扫描有效区域的比例关系
- (CGRect)setScanCropWitnBounds:(CGRect)bounds {
    
    CGFloat orginX, orginY, width, height;
    
    CGRect rect = self.frame;
    
    if (bounds.origin.x == 0) {
        
    }
//    orginX = (CGRectGetHeight(rect) - CGRectGetHeight(bounds))/2.0/CGRectGetHeight(rect);
//    orginY = (CGRectGetWidth(rect) - CGRectGetWidth(bounds))/2.0/CGRectGetWidth(rect);
    
    orginX = CGRectGetMinY(bounds)/CGRectGetHeight(rect);
    
    orginY = CGRectGetMinX(bounds)/CGRectGetWidth(rect);
    
    width = CGRectGetHeight(bounds)/CGRectGetHeight(rect);
    
    height = CGRectGetWidth(bounds)/CGRectGetWidth(rect);
    
    return CGRectMake(orginX, orginY, width, height);
}

- (CGRect)otherSet:(CGRect)cropRect {
    
    CGSize size = self.bounds.size;
    
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 640./480.;  //使用了1080p的图像输出
    if (p1 <= p2) {
        CGFloat fixHeight = self.bounds.size.width * 640. / 480.;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        return CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                          cropRect.origin.x/size.width,
                          cropRect.size.height/fixHeight,
                          cropRect.size.width/size.width);
    } else {
        CGFloat fixWidth = self.bounds.size.height * 480. / 640.;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        return CGRectMake(cropRect.origin.y/size.height,
                          (cropRect.origin.x + fixPadding)/fixWidth,
                          cropRect.size.height/size.height,
                          cropRect.size.width/fixWidth);
    }
}
+ (UIImage *)createQRcodeWith:(NSString *)string {
    
    return [self createQRcodeWith:string size:200];
}

+ (UIImage *)createQRcodeWith:(NSString *)string size:(CGFloat)size {
    
    if ([string isEqualToString:@""]) {
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:@"提示" message:@"二维码生成信息不能为空" preferredStyle:UIAlertControllerStyleAlert];
        [alertCtrl addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel handler:nil]];
        
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
        [vc presentViewController:alertCtrl animated:YES completion:nil];
        return nil;
    }
    
    //二维码滤镜
    CIFilter *filter=[CIFilter filterWithName:@"CIQRCodeGenerator"];
    //恢复滤镜的默认属性
    [filter setDefaults];
    //将字符串转换成NSData
    NSData *data=[string dataUsingEncoding:NSUTF8StringEncoding];
    //通过KVO设置滤镜inputmessage数据
    [filter setValue:data forKey:@"inputMessage"];
    //获得滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    //将CIImage转换成UIImage,并放大显示
    UIImage *image = [self resetSizeWithCIImage:outputImage withSize:size];
    
    return image;
}

//修改二维码大小
+ (UIImage *)resetSizeWithCIImage:(CIImage *)image withSize:(CGFloat) size {
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
