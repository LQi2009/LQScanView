//
//  LQRCoder.h
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/18.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 将生成的CIImage 以jpg格式保存到某个URL
 
 @param url 文件地址
 当为nil时保存至相册, 需要在Info.plist添加 NSPhotoLibraryAddUsageDescription
 @param image CIImage
 @return 是否保存成功
 */
UIKIT_EXTERN BOOL LQCIImageSavedJPEGToURL(NSURL * _Nullable url, CIImage * _Nonnull image);
UIKIT_EXTERN BOOL LQImageSavedJPEGToURL(NSURL * _Nullable url, UIImage * _Nonnull image);

/**
 将生成的CIImage 转换为JPEG的NSData
 
 @param image CIImage
 @return NSData
 */
UIKIT_EXTERN NSData * _Nullable LQJPEGDataFromCIImage(CIImage * _Nonnull image) ;
UIKIT_EXTERN NSData * _Nullable LQJPEGDataFromUIImage(UIImage * _Nonnull image) ;

NS_ASSUME_NONNULL_BEGIN

@interface LQRCoder : NSObject

/**
 识别图片二维码中的信息
 
 @param image 含有二维码的图片
 @param handler 二维码信息
 */
+ (void)scanQRImage:(UIImage * _Nullable)image
      resultHandler:(void(^)(NSArray * _Nullable results))handler ;

/**
 可识别二维码和条形码

 @param image 含有二维码或者条形码的图片
 @param handler 识别结果回调
 */
+ (void)scanQRBarImage:(UIImage * _Nullable)image
         resultHandler:(void(^)(NSArray * _Nullable results))handler;
/**
 生成二维码图片
 
 @param content 二维码中的信息, NSString 类型，或者 NSData
 @param size 二维码大小
 @param color 二维码颜色
 @param bgColor 二维码背景色
 @param logo 中心logo
 @param logoSize logo 尺寸
 @return 二维码图片
 */
+ (UIImage*)QRImageWithContent:(id)content
                        qrSize:(CGFloat)size
                     tintColor:(UIColor * _Nullable)color
               backgroundColor:(UIColor* _Nullable)bgColor
                          logo:(UIImage* _Nullable)logo
                      logoSize:(CGFloat)logoSize ;
+ (UIImage *)QRImageWithContent:(NSString *)string ;
+ (CIImage *)QRCIImageWithContent:(id)content
                           qrSize:(CGFloat)size
                        tintColor:(UIColor *_Nullable)color
                  backgroundColor:(UIColor *_Nullable)bgcolor ;

/**
 生成条形码
 
 @param content 条形码的内容，NSString 类型，或者 NSData
 @param size 条形码大小
 生成的条形码在显示在UIImageView的时候, 其size至少有一个值要大于 UIImageView 的size,否则,会显示模糊'
 建议将 UIImageView 的size传入
 @param color 条形码颜色
 @param bgcolor 条形码背景色
 @return 条形码图片
 */
+ (UIImage *)BarImageWithContent:(NSString *)content
                         barSize:(CGSize)size
                       tintColor:(UIColor *_Nullable)color
                 backgroundColor:(UIColor *_Nullable)bgcolor ;
+ (UIImage *)BarImageWithContent:(NSString *)content ;
+ (CIImage *)BarCIImageWithContent:(NSString *)content
                           barSize:(CGSize)size
                         tintColor:(UIColor *_Nullable)color
                   backgroundColor:(UIColor *_Nullable)bgcolor ;

// 异步执行
+ (void)QRImageAsyncWithContent:(NSString *)string
                completeHandler:(void(^)(UIImage *image)) handler;
+ (void)QRImageAsyncWithContent:(id)content
                         qrSize:(CGFloat)size
                      tintColor:(UIColor * _Nullable)color
                backgroundColor:(UIColor* _Nullable)bgColor
                           logo:(UIImage* _Nullable)logo
                       logoSize:(CGFloat)logoSize
                completeHandler:(void(^)(UIImage *image)) handler;

+ (void)BarImageAsyneWithContent:(NSString *)content
                 completeHandler:(void(^)(UIImage *image)) handler;
+ (void)BarImageAsyncWithContent:(NSString *)content
                         barSize:(CGSize)size
                       tintColor:(UIColor *_Nullable)color
                 backgroundColor:(UIColor *_Nullable)bgcolor
                 completeHandler:(void(^)(UIImage *image)) handler ;
@end

NS_ASSUME_NONNULL_END
