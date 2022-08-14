//
//  LQScanView.h
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/15.
//  Copyright © 2019 Q.ice. All rights reserved.
//


#import <UIKit/UIKit.h>

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

@interface LQRScanOverlayView : UIView

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
- (void) startAnimate;

/**
 停止扫描
 */
- (void) stopAnimate ;

- (void) showActivity ;
- (void) hiddenActivity ;
@end


NS_ASSUME_NONNULL_END
