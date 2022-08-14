//
//  LQScanViewController.m
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/16.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import "LQScanViewController.h"
#import "LQRScanOverlayView.h"
#import "LQRCoder.h"
#import "LQRScanner.h"

@interface LQScanViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, LQRScannerDelegate> {
    
    BOOL __isNavigationBarHidden;
    UIInterfaceOrientation __currentOrientation;
}

@property (strong, nonatomic) LQRScanOverlayView *overlayView;
@property (strong, nonatomic) LQRScanner *scanner;
@property (nonatomic, strong) UIButton * backButton ;
@property (nonatomic, strong) UIButton * photoButton ;
@property (nonatomic, strong) UIButton * lightButton ;
@property (nonatomic, strong) UILabel * titleLabel ;
@property (nonatomic, copy) LQScanCompleteHandler completeHandler ;
@end

@implementation LQScanViewController

- (void) didScanedWithCompleteHandler:(LQScanCompleteHandler) handler {
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
    
    [self.overlayView startAnimate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.overlayView.frame = self.view.bounds;
    self.scanner.scanArea = self.overlayView.scanArea;
    self.scanner.frame = self.view.bounds;
    
    self.backButton.frame = CGRectMake(self.view.safeAreaInsets.left + 10, self.view.safeAreaInsets.top + 10, 40, 40);
    self.titleLabel.bounds = CGRectMake(0, 0, 100, 30);
    self.titleLabel.center = CGPointMake(self.view.center.x, self.view.safeAreaInsets.top + 25);
    self.photoButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - self.view.safeAreaInsets.right - 50, self.view.safeAreaInsets.top + 10, 40, 40);
    self.lightButton.bounds = CGRectMake(0, 0, 100, 100);
    self.lightButton.center = self.view.center;
}

- (void) stopScan {
    [self.overlayView stopAnimate];
    [self.scanner stopScanning];
}

- (void) startScan {
    
}

- (void) photoButtonAction {
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:NO completion:nil];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.overlayView startAnimate];
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
    
    [self.overlayView startAnimate];
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (UIButton *)lightButton {
    if (_lightButton == nil) {
        _lightButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_lightButton setImage:[UIImage imageNamed:@"light_close"] forState:(UIControlStateNormal)];
        _lightButton.alpha = 0;
        [_lightButton setImage:[UIImage imageNamed:@"light_open"] forState:(UIControlStateSelected)];
        [_lightButton addTarget:self action:@selector(lightButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        [self.view addSubview:_lightButton];
    }
    
    return _lightButton;
}

- (void) lightButtonAction:(UIButton *) button {
    button.selected = !button.selected;
    [LQRScanner turnTorch:button.selected];
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
    
    [self.scanner stopScanning];
    [self.overlayView stopAnimate];
    if (self.lightButton.selected == YES) {
        [self lightButtonAction:self.lightButton];
    }
    
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)scanner:(LQRScanner *)scanner didScanned:(NSArray<LQRScanItem *> *)results {
    
    LQRScanItem *res = [results firstObject];
    
    [self backButtonAction];
    if (self.completeHandler) {
        self.completeHandler(res.result);
    }
}

- (void)scanner:(LQRScanner *)scanner statusChanged:(LQRScannerStatus)status {
    
    NSString *msg = @"";
    switch (status) {
        case LQRScannerWillStartSession:
            // 启动的时候，会有2s左右的耗时，
            msg = @"LQRScannerWillStartSession";
            [self.overlayView showActivity];
            break;
        case LQRScannerDidStartSession:
            msg = @"LQRScannerDidStartSession";
            [self.overlayView hiddenActivity];
            break;
        case LQRScannerDidEnterBackground:
            msg = @"LQRScannerDidEnterBackground";
            break;
        case LQRScannerWillEnterForeground:
            msg = @"LQRScannerWillEnterForeground";
            break;
        case LQRScannerStartScanning:
            msg = @"LQRScannerStartScanning";
            break;
        case LQRScannerStopScanning:
            msg = @"LQRScannerStopScanning";
            break;
        case LQRScannerPrepareDone:
            msg = @"LQRScannerPrepareDone";
            [scanner startScanning];
            break;
            
        default:
            break;
    }
}

- (void) scanner:(LQRScanner *)scanner lightChanged:(CGFloat)value {
//    NSLog(@"%f", value);
    BOOL isShow = value > -1 ? NO: YES;
    [self showLightbutton:isShow];
}

- (void)scannerScanFailed:(LQRScanner *)scanner {
    [self backButtonAction];
    if (self.completeHandler) {
        self.completeHandler(nil);
    }
}
- (void) showLightbutton:(BOOL) show {
    
    if (show) {
        if (self.lightButton.alpha > 0) {
            return;
        }
        
        [self.overlayView stopAnimate];
        [UIView animateWithDuration:0.5 animations:^{
            self.lightButton.alpha = 1.0;
        }];
    } else {
        [self.overlayView startAnimate];
        if (self.lightButton.selected == NO) {
            self.lightButton.alpha = 0;
        }
    }
}

- (LQRScanOverlayView *)overlayView {
    if (_overlayView == nil) {
        _overlayView = [[LQRScanOverlayView alloc] initWithFrame:self.view.bounds];
        _overlayView.autoresizesSubviews = YES;
        [self.view addSubview:_overlayView];
    }
    
    return _overlayView;
}

- (LQRScanner *)scanner {
    if (_scanner == nil) {
        _scanner = [[LQRScanner alloc] init];
        _scanner.delegate = self;
        [self.overlayView.layer insertSublayer:_scanner.layer atIndex:0];
    }
    
    return _scanner;
}

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
