//
//  RBScanViewController.m
//  LQScanView
//
//  Created by NewTV on 2022/3/31.
//  Copyright © 2022 Q.ice. All rights reserved.
//

#import "RBScanViewController.h"
#import "RBScanView.h"
#import "LQRCoder.h"

@interface RBScanViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate,RBScanViewDelegate> {
    
    BOOL __isNavigationBarHidden;
    UIInterfaceOrientation __currentOrientation;
}

@property (nonatomic, strong) RBScanView *scanView;
@property (nonatomic, strong) UIButton * backButton ;
@property (nonatomic, strong) UIButton * photoButton ;
//@property (nonatomic, strong) UIButton * lightButton ;
@property (nonatomic, strong) UILabel * titleLabel ;
@property (nonatomic, copy) RBScanCompleteHandler completeHandler ;
@end

@implementation RBScanViewController
- (void) didScanedWithCompleteHandler:(RBScanCompleteHandler) handler {
    self.completeHandler = handler;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController) {
        __isNavigationBarHidden = self.navigationController.navigationBarHidden;
        if (__isNavigationBarHidden == NO) {
            self.navigationController.navigationBarHidden = YES;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = __isNavigationBarHidden;
    }
    
    if (__currentOrientation != UIInterfaceOrientationPortrait) {
        [self rotateScreen:__currentOrientation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.scanView startScan];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.scanView.frame = self.view.bounds;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.scanView.frame = self.view.bounds;
//    self.scanner.scanArea = self.overlayView.scanArea;
//    self.scanner.frame = self.view.bounds;
    
    self.backButton.frame = CGRectMake(self.view.safeAreaInsets.left + 10, self.view.safeAreaInsets.top + 10, 40, 40);
    self.titleLabel.bounds = CGRectMake(0, 0, 100, 30);
    self.titleLabel.center = CGPointMake(self.view.center.x, self.view.safeAreaInsets.top + 25);
    self.photoButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - self.view.safeAreaInsets.right - 50, self.view.safeAreaInsets.top + 10, 40, 40);
}

- (void) stopScan {
    [self.scanView stopScan];
}

- (void) photoButtonAction {
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:NO completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.scanView startScan];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        [LQRCoder scanQRBarImage:image resultHandler:^(NSArray * _Nullable results) {
            
            if (self.completeHandler) {
                self.completeHandler([results firstObject]);
            }
        }];
        
        [picker dismissViewControllerAnimated:YES completion:^{
            [self backButtonAction];
        }];
        return;
    }
    
    [self.scanView startScan];
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)scanView:(RBScanView *_Nonnull)scan
      didScanned:(NSArray<RBScanResult *> * _Nullable)results {
    
    RBScanResult *res = [results firstObject];
    
    [self backButtonAction];
    if (self.completeHandler) {
        self.completeHandler(res.result);
    }
}

- (void)scanViewScanFailed:(RBScanView *_Nonnull)scan {
    [self backButtonAction];
    if (self.completeHandler) {
        self.completeHandler(nil);
    }
}

- (UIButton *)backButton {
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_backButton setImage:[UIImage imageNamed:@"qrcoder_back"] forState:(UIControlStateNormal)];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:(UIControlEventTouchUpInside)];
        [self.view addSubview:_backButton];
    }
    
    return _backButton;
}

- (void) backButtonAction {
    
    [self.scanView stopScan];
//    if (self.lightButton.selected == YES) {
//        [self lightButtonAction:self.lightButton];
//    }
    
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//- (void) showLightbutton:(BOOL) show {
//
//    if (show) {
//        if (self.lightButton.alpha > 0) {
//            return;
//        }
//
//        [self.scanView stopAnimate];
//        [UIView animateWithDuration:0.5 animations:^{
//            self.lightButton.alpha = 1.0;
//        }];
//    } else {
//        [self.scanView startAnimate];
//        if (self.lightButton.selected == NO) {
//            self.lightButton.alpha = 0;
//        }
//    }
//}
//
- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.text = @"扫一扫";
        [self.view addSubview:_titleLabel];
    }

    return _titleLabel;
}

- (UIButton *)photoButton {
    if (_photoButton == nil) {
        _photoButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        _photoButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_photoButton setTitle:@"相册" forState:(UIControlStateNormal)];
        [_photoButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [_photoButton addTarget:self action:@selector(photoButtonAction) forControlEvents:(UIControlEventTouchUpInside)];
        [self.view addSubview:_photoButton];
    }

    return _photoButton;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (RBScanView *)scanView {
    if (!_scanView) {
        _scanView = [[RBScanView alloc] init];
        _scanView.delegate = self;
        [self.view addSubview:_scanView];
    }
    return _scanView;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//强制旋转屏幕
- (void)rotateScreen:(UIInterfaceOrientation)orientation {
    
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    NSInteger val = orientation;
    [invocation setArgument:&val atIndex:2];//前两个参数已被target和selector占用
    [invocation invoke];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
