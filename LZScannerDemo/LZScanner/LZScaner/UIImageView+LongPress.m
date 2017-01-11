//
//  UIImageView+LongPress.m
//  LZScaner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import "UIImageView+LongPress.h"
#import "LZScanner.h"

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
        
        [LZScanner scanImage:self.image result:^(NSString *result) {
            
            if (backBlock) {
                backBlock(result);
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
