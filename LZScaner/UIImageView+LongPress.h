//
//  UIImageView+LongPress.h
//  LZScaner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^resultBlock)(NSString *result);
@interface UIImageView (LongPress)

- (void)longPressScan:(resultBlock)result;
@end
