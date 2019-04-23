//
//  LQScanViewController.h
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/16.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LQScanCompleteHandler)(id info);
@interface LQScanViewController : UIViewController

- (void) didScanedWithCompleteHandler:(LQScanCompleteHandler) handler ;
@end

NS_ASSUME_NONNULL_END
