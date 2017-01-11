//
//  LZScanView.h
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import <UIKit/UIKit.h>

// 扫描视图
@interface LZScanView : UIView

@property (nonatomic) CGRect windowRect;

- (void)startAnimation;
- (void)stopAnimation;
@end

// 蒙版遮罩视图
@interface LZScanOverlayView : UIView

/** 中间窗口的中心点 */
@property (nonatomic,readonly) CGPoint windowCenter;

/** 中间窗口的frame */
@property (nonatomic,readonly) CGRect windowFrame;
@end
