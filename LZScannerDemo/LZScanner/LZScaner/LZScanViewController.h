//
//  LZScanViewController.h
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^backBlock)(NSString *result);
@interface LZScanViewController : UIViewController

@property (nonatomic, copy) backBlock resultBlock;
@end
