//
//  UIImageView+LongPress.m
//  LZScaner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import "UIImageView+LongPress.h"
#import "LQRCoder.h"

static resultBlock backBlock;
static BOOL isAlreadyAlert = NO;

@implementation UIImageView (LongPress)

- (void)longPressScan:(resultBlock)result {
    
    self.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
    
    [self addGestureRecognizer:press];
    
    backBlock = result;
}

- (void)longPress:(UILongPressGestureRecognizer *)press {
    
    if (isAlreadyAlert) {
        
        return;
    }
    
    isAlreadyAlert = YES;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *scan = [UIAlertAction actionWithTitle:@"识别图中二维码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        
//        [LQRCoder scanQRImage:self.image resultHandler:^(NSArray * _Nullable results) {
//            if (backBlock) {
//                backBlock(results.firstObject);
//            }
//        }];
        [LQRCoder scanQRBarImage:self.image resultHandler:^(NSArray * _Nullable results) {
            if (backBlock) {
                backBlock(results.firstObject);
            }
        }];
        
        isAlreadyAlert = NO;
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        isAlreadyAlert = NO;
    }];
    
    [alert addAction:scan];
    [alert addAction:cancel];
    
    UIViewController *vc = [[UIApplication sharedApplication] keyWindow].rootViewController;
    
    [vc presentViewController:alert animated:YES completion:nil];
}
@end
