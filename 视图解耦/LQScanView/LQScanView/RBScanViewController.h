//
//  RBScanViewController.h
//  LQScanView
//
//  Created by NewTV on 2022/3/31.
//  Copyright © 2022 Q.ice. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^RBScanCompleteHandler)(id __nullable info);
@interface RBScanViewController : UIViewController

- (void) didScanedWithCompleteHandler:(RBScanCompleteHandler) handler ;
@end

NS_ASSUME_NONNULL_END
