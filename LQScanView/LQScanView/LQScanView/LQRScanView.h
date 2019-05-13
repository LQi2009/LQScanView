//
//  LQScanView.h
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/15.
//  Copyright © 2019 Q.ice. All rights reserved.
//
/*
 需要在 Info.plist 文件中添加字段 NSCameraUsageDescription, 描述使用相机权限
 */

#import <UIKit/UIKit.h>

@class LQRScanView;
@class LQRScanResult;
@protocol LQRScanViewDelegate <NSObject>

/**
 扫描成功的回调

 @param scan 当前视图
 @param results 扫描信息
 */
- (void)scanView:(LQRScanView *_Nonnull)scan
      didScanned:(NSArray<LQRScanResult *> * _Nullable)results;
@optional

/**
 检测到当前光线值的回调

 @param scan 当前视图
 @param value 光线值, 值越大,光线越充足
 */
- (void)scanView:(LQRScanView *_Nonnull)scan
    lightChanged:(CGFloat)value;
- (void)scanViewCamaraDisable:(LQRScanView *_Nonnull)scan;
- (void)scanViewScanFailed:(LQRScanView *_Nonnull)scan ;
@end

typedef enum : NSUInteger {
    LQRWarnTextAlignmentBottom,
    LQRWarnTextAlignmentTop,
    LQRWarnTextAlignmentCenter,
} LQRWarnTextAlignment;

typedef enum : NSUInteger {
    
    LQRScanframeTypeIn,
    LQRScanframeTypeOut,
    LQRScanframeTypeOn,
} LQRScanframeType;

NS_ASSUME_NONNULL_BEGIN

@interface LQRScanView : UIView

/**
 是否检测当前环境光线强度, 通过代理 'scanView:lightChanged:' 反馈
 默认不检测
 */
@property (nonatomic, assign) IBInspectable BOOL lightDetectionEnable ;

/**
 提示文字
 默认为 '将二维码放入框内，即可自动扫描'
 */
@property (nonatomic, copy) IBInspectable NSString * warnText ;

/**
 扫描线图片名称
 默认为 'reader_scan_scanline'
 */
@property (nonatomic, copy) IBInspectable NSString * scanlineName ;
/**
 扫描框图片名称
 默认为 'reader_scan_scanCamera'
 */
@property (nonatomic, copy) IBInspectable NSString * scanframeName ;

/**
 最大识别次数, 当识别次数达到该值,仍未识别出结果时停止扫描
 通过 scanViewScanFailed: 回调
 默认为 0,不限制
 */
@property (nonatomic, assign) IBInspectable NSUInteger maxScanCount ;

/**
 代理
 */
@property (nonatomic, assign) IBOutlet id <LQRScanViewDelegate> delegate;

/**
 扫描区域, 默认屏幕宽*0.7, 最大300, 居中
 当为 CGRectZero 的时候, 全屏扫描
 */
@property (nonatomic) IBInspectable CGRect scanArea ;

/**
 提示文字的位置
 */
@property (nonatomic, assign) LQRWarnTextAlignment warnTextAlignment ;

/**
 扫描框的位置
 */
@property (nonatomic, assign) LQRScanframeType scanframeType ;

/**
 开始扫描
 */
- (void) startScanning ;
- (void) startAnimate;

/**
 停止扫描
 */
- (void) stopScanning ;
- (void) stopAnimate ;

/**
 聚焦
 */
- (void) autoFocusScanCenter ;

/**
 打开闪光灯

 @param on YES: 打开; NO: 关闭
 */
+ (void)turnTorch:(BOOL) on ;

/**
 是否有相机权限

 @return YES or NO
 */
+ (BOOL)isCameraEnable ;
@end

@interface LQRScanResult : NSObject

@property (nonatomic, copy) NSString * result ;
@end
NS_ASSUME_NONNULL_END
