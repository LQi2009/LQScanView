//
//  RBScanView.h
//  RBScanView
//
//  Created by NewTV on 2022/3/31.
//  Copyright © 2022 Q.ice. All rights reserved.
// 未完成

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RBScanResult;
@class RBScanView;
@protocol RBScanViewDelegate <NSObject>

/**
 扫描成功的回调

 @param scan 当前视图
 @param results 扫描信息
 */
- (void)scanView:(RBScanView *_Nonnull)scan
      didScanned:(NSArray<RBScanResult *> * _Nullable)results;
@optional
- (void)scanViewScanFailed:(RBScanView *_Nonnull)scan ;
@end

typedef enum : NSUInteger {
    RBScanViewWarnTextAlignmentBottom,
    RBScanViewWarnTextAlignmentTop,
    RBScanViewWarnTextAlignmentCenter,
} RBScanViewWarnTextAlignment;

typedef enum : NSUInteger {
    
    RBScanViewframeTypeIn,
    RBScanViewframeTypeOut,
    RBScanViewframeTypeOn,
} RBScanViewframeType;

@interface RBScanView : UIView

@property (nonatomic) id <RBScanViewDelegate> delegate;

/// 最大扫描次数
@property (nonatomic, assign) NSInteger maxScanCount ;
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
 扫描区域, 默认屏幕宽*0.7, 最大300, 居中
 */
@property (nonatomic) IBInspectable CGRect scanArea ;

/// 提示文字的位置
@property (nonatomic, assign) RBScanViewWarnTextAlignment warnTextAlignment ;

/// 扫描框的位置
@property (nonatomic, assign) RBScanViewframeType scanframeType ;

/// 开始扫描
- (void) startScan;

/// 停止扫描
- (void) stopScan ;

+ (BOOL)isCameraEnable ;
@end

@interface RBScanResult : NSObject

@property (nonatomic, copy) NSString * result ;
@end

NS_ASSUME_NONNULL_END
