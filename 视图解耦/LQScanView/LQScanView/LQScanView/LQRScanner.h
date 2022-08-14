//
//  LQRScanner.h
//  LQScanView
//
//  Created by 刘启强 on 2022/3/29.
//  Copyright © 2022 Q.ice. All rights reserved.
//

 // 需要在 Info.plist 文件中添加字段 NSCameraUsageDescription, 描述使用相机权限
 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    
    LQRScannerStatusUnknow,
    LQRScannerPrepareDone,
    LQRScannerWillStartSession,
    LQRScannerDidStartSession,
    LQRScannerDidEnterBackground,
    LQRScannerWillEnterForeground,
    LQRScannerStartScanning,
    LQRScannerStopScanning,
} LQRScannerStatus;

@protocol LQRScannerDelegate ;
@interface LQRScanner : NSObject

/// 是否开启光线亮度检测，如果开启，会回调‘scanner:lightChanged:’事件
/// 默认关闭：NO
@property (nonatomic, assign) BOOL lightDetectionEnable ;

/// 是否自动开启，默认：YES
/// 如果设置为NO，需要在回调
/// ‘LQRScannerPrepareDone’状态时调用’startScanning‘
@property (nonatomic, assign) BOOL isAutoStartScan ;

/// 最大扫描次数
@property (nonatomic, assign) NSInteger maxScanCount ;

/// 有效扫描区域，不设置或者设置为CGRectZero，则全屏有效
@property (nonatomic) CGRect scanArea ;

/// 坐标
@property (nonatomic) CGRect frame ;
@property (nonatomic, weak) id<LQRScannerDelegate> delegate ;
@property (nonatomic, strong, readonly) CALayer *layer;
//@property (nonatomic, strong) UIView *view;

- (void) startScanning ;
- (void) stopScanning ;

- (void) autoFocusScanCenter ;
+ (void)turnTorch:(BOOL) on ;
+ (BOOL)isCameraEnable ;
@end


@class LQRScanItem;
@protocol LQRScannerDelegate <NSObject>

- (void) scanner:(LQRScanner *) scanner didScanned:(NSArray<LQRScanItem *> *) results;

@optional
- (void) scanner:(LQRScanner *) scanner  statusChanged:(LQRScannerStatus) status;
- (void) scanner:(LQRScanner *_Nonnull)scanner
    lightChanged:(CGFloat) value;
- (void) scannerCamaraDisable:(LQRScanner *_Nonnull)scanner;
- (void) scannerScanFailed:(LQRScanner *_Nonnull)scanner;

@end

@interface LQRScanItem : NSObject

@property (nonatomic, copy) NSString * result ;
@end
NS_ASSUME_NONNULL_END
