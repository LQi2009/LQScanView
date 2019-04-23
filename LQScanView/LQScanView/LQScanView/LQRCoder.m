//
//  LQRCoder.m
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/18.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import "LQRCoder.h"
#import <Vision/Vision.h>

BOOL LQCIImageSavedJPEGToURL(NSURL *_Nullable url, CIImage * _Nonnull image) {
    
    CIContext *ctx = [CIContext contextWithOptions:nil];
    
    if (!url) {
        
        NSData *data = [ctx JPEGRepresentationOfImage:image colorSpace:[image colorSpace] options:@{}];
        UIImage *img = [UIImage imageWithData:data];
        if (!img) {
            return NO;
        }
        
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        return YES;
    }
    
    NSError *error;
    BOOL su = [ctx writeJPEGRepresentationOfImage:image toURL:url colorSpace:[image colorSpace] options:@{} error:&error];
    if (su == NO) {
        NSLog(@"%@", error.description);
    }
    return su;
}

BOOL LQImageSavedJPEGToURL(NSURL * _Nullable url, UIImage * _Nonnull image){
    
    CIContext *ctx = [CIContext contextWithOptions:nil];
    
    if (!url) {
        
        CIImage *ciimage = image.CIImage;
        UIImage *savedImage = nil;
        if (ciimage) {
            NSData *data = [ctx JPEGRepresentationOfImage:ciimage colorSpace:[ciimage colorSpace] options:@{}];
            savedImage = [UIImage imageWithData:data];
        } else {
            savedImage = image;
        }
        
        if (savedImage == nil) {
            return NO;
        }
        UIImageWriteToSavedPhotosAlbum(savedImage, nil, nil, nil);
        return YES;
    }
    
    CIImage *ciimage = image.CIImage;
    if (ciimage) {
        NSError *error;
        BOOL su = [ctx writeJPEGRepresentationOfImage:ciimage toURL:url colorSpace:[ciimage colorSpace] options:@{} error:&error];
        if (su == NO) {
            NSLog(@"%@", error.description);
        }
        return su;
    }
    
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    BOOL rs = [data writeToURL:url atomically:YES];
    return rs;
}

NSData * _Nullable LQJPEGDataFromCIImage(CIImage * _Nonnull image) {
    
    CIContext *ctx = [CIContext contextWithOptions:nil];
    
    NSData *data = [ctx JPEGRepresentationOfImage:image colorSpace:[image colorSpace] options:@{}];
    return data;
}

NSData * _Nullable LQJPEGDataFromUIImage(UIImage * _Nonnull image) {
    
    CIImage *ciimage = image.CIImage;
    if (ciimage) {
        CIContext *ctx = [CIContext contextWithOptions:nil];
        
        NSData *data = [ctx JPEGRepresentationOfImage:ciimage colorSpace:[ciimage colorSpace] options:@{}];
        return data;
    }
    
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    return data;
}

@implementation LQRCoder

+ (void)scanQRImage:(UIImage * _Nullable)image
      resultHandler:(void(^)(NSArray * _Nullable results))handler {
    
    if (image == nil) {
        if (handler) {
            handler(nil);
        }
        return;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        //2.初始化一个监测器
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        
        CIImage *ci = image.CIImage;
        if (ci == nil) {
            ci = [CIImage imageWithCGImage:image.CGImage];
        }
        
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:ci];
        
        NSMutableArray *res = [NSMutableArray arrayWithCapacity:features.count];
        
        if(features.count > 0) {
            
            for (CIQRCodeFeature *feature in features) {
                NSString *scanResult = feature.messageString;
                if (scanResult) {
                    [res addObject:scanResult];
                } else {
                    [res addObject:@"none"];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                
                NSArray *arr = [NSArray arrayWithArray:res];
                handler(arr);
            }
        });
    });
}

+ (void)scanQRBarImage:(UIImage * _Nullable)image
         resultHandler:(void(^)(NSArray * _Nullable results))handler {

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSMutableArray *res = [NSMutableArray array];
        VNImageRequestHandler *reqHandler = nil;
        if (image.CIImage) {
            reqHandler = [[VNImageRequestHandler alloc]initWithCIImage:image.CIImage options:@{}];
        } else {
            reqHandler = [[VNImageRequestHandler alloc]initWithCGImage:image.CGImage options:@{}];
        }
        
        VNDetectBarcodesRequest *req = [[VNDetectBarcodesRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            
            NSArray *obs = request.results;
            for (VNBarcodeObservation *bar in obs) {
                if ([bar isKindOfClass:[VNBarcodeObservation class]]) {
                    NSString *str = bar.payloadStringValue;
                    if (str) {
                        [res addObject:str];
                    } else {
                        [res addObject:@"none"];
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) {
                    handler(res);
                }
            });
        }];
        
        NSError *error ;
        req.symbologies = [VNDetectBarcodesRequest supportedSymbologies];
        [reqHandler performRequests:@[req] error:&error];
    });
}

#pragma mark -
+ (void)QRImageAsyncWithContent:(NSString *)string
                  completeHandler:(void(^)(UIImage *image)) handler {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        UIImage *image = [self QRImageWithContent:string];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(image);
            }
        });
    });
}

+ (void)QRImageAsyncWithContent:(id)content
                        qrSize:(CGFloat)size
                     tintColor:(UIColor * _Nullable)color
               backgroundColor:(UIColor* _Nullable)bgColor
                          logo:(UIImage* _Nullable)logo
                      logoSize:(CGFloat)logoSize
                completeHandler:(void(^)(UIImage *image)) handler {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        UIImage *image = [self QRImageWithContent:content qrSize:size tintColor:color backgroundColor:bgColor logo:logo logoSize:logoSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(image);
            }
        });
    });
}

+ (UIImage *)QRImageWithContent:(NSString *)string {
    
    return [self QRImageWithContent:string
                             qrSize:300
                          tintColor:nil
                    backgroundColor:nil
                               logo:nil
                           logoSize:0];
}

+ (UIImage*)QRImageWithContent:(id)content
                        qrSize:(CGFloat)size
                     tintColor:(UIColor * _Nullable)color
               backgroundColor:(UIColor* _Nullable)bgColor
                          logo:(UIImage* _Nullable)logo
                      logoSize:(CGFloat)logoSize {
    
    CIImage *ciimage = [self QRCIImageWithContent:content
                                           qrSize:size
                                        tintColor:color
                                  backgroundColor:bgColor];
    
    UIImage *image = [UIImage imageWithCIImage:ciimage];
    if (!logo) return image;
    if (!image) return nil;
    
    CGFloat logoWidth = logoSize;
    CGRect logoFrame = CGRectMake((image.size.width - logoWidth) /  2,(image.size.width - logoWidth) / 2,logoWidth,logoWidth);
    
    // 绘制logo
    UIGraphicsBeginImageContextWithOptions(image.size, false, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    
    [logo drawInRect:logoFrame];
    
    UIImage* QRCodeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return QRCodeImage;
    
    //    CGSize qrsize = CGSizeMake(size, size);
    //    //绘制
    //    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    //    UIGraphicsBeginImageContext(qrsize);
    //    CGContextRef context = UIGraphicsGetCurrentContext();
    //    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    //    CGContextScaleCTM(context, 1.0, -1.0);
    //    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    //    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    //    CGImageRelease(cgImage);
    //
    //    return codeImage;
}

+ (CIImage *)QRCIImageWithContent:(id)content
                           qrSize:(CGFloat)size
                        tintColor:(UIColor *_Nullable)color
                  backgroundColor:(UIColor *_Nullable)bgcolor {
    
    if (!content) { return nil; }
    
    // 转换成NSData
    NSData *data = nil;
    if ([content isKindOfClass:[NSData class]]) {
        data = content;
    } else if ([content isKindOfClass:[NSString class]]) {
        data=[content dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (data == nil) {
        return nil;
    }
    
    if (size == 0) {
        size = 300;
    }
    
    //二维码滤镜
    CIFilter *filter=[CIFilter filterWithName:@"CIQRCodeGenerator"];
    //恢复滤镜的默认属性
    [filter setDefaults];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    //通过KVO设置滤镜inputmessage数据
    [filter setValue:data forKey:@"inputMessage"];
    //获得滤镜输出的图像
    CIImage *qrImage = [filter outputImage];
    
    if (color || bgcolor) {
        //3.颜色滤镜
        CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [colorFilter setValue:qrImage forKey:@"inputImage"];
        if (color) {
            // 二维码颜色
            [colorFilter setValue:[CIColor colorWithCGColor:color.CGColor] forKey:@"inputColor0"];
        }
        if (bgcolor) {
            // 背景色
            [colorFilter setValue:[CIColor colorWithCGColor:bgcolor.CGColor] forKey:@"inputColor1"];
        }
        
        qrImage = colorFilter.outputImage;
    }
    
    CGFloat scale = size / qrImage.extent.size.width;
    
    qrImage = [qrImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)];
    
    return qrImage;
}

+ (void)BarImageAsyneWithContent:(NSString *)content
                 completeHandler:(void(^)(UIImage *image)) handler {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        UIImage *image = [self BarImageWithContent:content];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(image);
            }
        });
    });
}
+ (void)BarImageAsyncWithContent:(NSString *)content
                              barSize:(CGSize)size
                            tintColor:(UIColor *_Nullable)color
                      backgroundColor:(UIColor *_Nullable)bgcolor
                      completeHandler:(void(^)(UIImage *image)) handler {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        UIImage *image = [self BarImageWithContent:content barSize:size tintColor:color backgroundColor:bgcolor];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(image);
            }
        });
    });
}


+ (UIImage *)BarImageWithContent:(NSString *)content {
    
    return [self BarImageWithContent:content
                             barSize:CGSizeZero
                           tintColor:nil
                     backgroundColor:nil];
}

+ (UIImage *)BarImageWithContent:(NSString *)content
                         barSize:(CGSize)size
                       tintColor:(UIColor *_Nullable)color
                 backgroundColor:(UIColor *_Nullable)bgcolor {
    
    CIImage *barImage = [self BarCIImageWithContent:content barSize:size tintColor:color backgroundColor:bgcolor];
    
    UIImage *image = [UIImage imageWithCIImage:barImage];
    return image;
}

+ (CIImage *)BarCIImageWithContent:(NSString *)content
                           barSize:(CGSize)size
                         tintColor:(UIColor *_Nullable)color
                   backgroundColor:(UIColor *_Nullable)bgcolor {
    
    
    if (!content) { return nil; }
    // 转换成NSData
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    if (data == nil) {
        return nil;
    }
    
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = CGSizeMake(500, 309);
    }
    
    //二维码滤镜
    CIFilter *filter=[CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    [filter setDefaults];
    // 设置生成的条形码的上，下，左，右的margins的值
    //    [filter setValue:[NSNumber numberWithInteger:0] forKey:@"inputQuietSpace"];
    
    [filter setValue:data forKey:@"inputMessage"];
    //获得滤镜输出的图像
    CIImage *barImage = [filter outputImage];
    
    if (color || bgcolor) {
        //3.颜色滤镜
        CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [colorFilter setValue:barImage forKey:@"inputImage"];
        if (color) {
            // 二维码颜色
            [colorFilter setValue:[CIColor colorWithCGColor:color.CGColor] forKey:@"inputColor0"];
        }
        if (bgcolor) {
            // 背景色
            [colorFilter setValue:[CIColor colorWithCGColor:bgcolor.CGColor] forKey:@"inputColor1"];
        }
        
        barImage = colorFilter.outputImage;
    }
    
    // 消除模糊
    // 这里需要注意: size 的长和宽至少有一个要大于UIImageView的size才会不模糊
    CGFloat scaleX = size.width / barImage.extent.size.width;
    CGFloat scaleY = size.height / barImage.extent.size.height;
    
    barImage = [barImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    return barImage;
}




//修改二维码大小
+ (UIImage *)resetSizeWithCIImage:(CIImage *)image withSize:(CGFloat) size {
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    //    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
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
@end
