//
//  LZScanner.h
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LZScanner;
@protocol LZScannerDelegate <NSObject>

- (void)scanner:(LZScanner *)scanner didScanned:(NSString *)result;
@end
@interface LZScanner : UIView

@property (nonatomic) CGRect scanArea;
@property (nonatomic, assign) id <LZScannerDelegate> delegate;
/* 打开,关闭灯光*/
+ (void)turnTorchOn:(BOOL)on;
/* 是否支持相机,有无使用相机权限 */
+ (BOOL)isCameraEnable;
/* 识别图片中的二维码,可单独使用 
 *
 * image: 含有二维码的图片
 * block: 识别结果回调
 */
+ (void)scanImage:(UIImage*)image result:(void(^)(NSString *result))block;
/* 生成二维码
 *
 * string: 二维码包含的文字
 * 
 * return: 生成的二维码
 */
+ (UIImage *)createQRcodeWith:(NSString *)string;
/* 生成二维码
 * 
 * string: 二维码包含的文字
 * size: 二维码的大小
 *
 * return: 生成的二维码
 */
+ (UIImage *)createQRcodeWith:(NSString *)string size:(CGFloat)size;

/* 开始扫描 */
- (void)startScanning;
/* 停止扫描 */
- (void)stopScanning;
/* 正在扫描 */
- (BOOL)isScanning;
@end

