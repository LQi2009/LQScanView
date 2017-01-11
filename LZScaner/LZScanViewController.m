//
//  LZScanViewController.m
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//
/*
 iOS 10 需要在info.plist添加以下字段
 
 <key>NSPhotoLibraryUsageDescription</key>
 <string>App需要您的同意,才能访问相册</string>
 
 <key>NSCameraUsageDescription</key>
 <string>App需要您的同意,才能访问相机</string>
 
 */

#import "LZScanViewController.h"
#import "LZScanView.h"
#import "LZScanConfigFiles.h"
#import "LZScanner.h"

@interface LZScanViewController ()<LZScannerDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    BOOL sholdShowNaviBar;
}

@property (strong,nonatomic)LZScanner *scanner;
@property (nonatomic, strong)LZScanView *scanView;
@end

@implementation LZScanViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //判断一下之前是否隐藏了系统导航,来确定在视图消失时是否隐藏系统导航
    if (self.navigationController.navigationBarHidden) {
        sholdShowNaviBar = NO;
    } else {
        sholdShowNaviBar = YES;
        self.navigationController.navigationBarHidden = YES;
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.scanner startScanning];
    [self.scanView startAnimation];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scanner stopScanning];
    [self.scanView stopAnimation];
    if (sholdShowNaviBar) {
        self.navigationController.navigationBarHidden = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //使用通知监听app进入后台
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
//    @"enterBackground"
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.scanner.delegate = self;
    [self createScanView];
    [self customNaviBar];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)enterBackground {
    [self.scanner stopScanning];
    [self.scanView stopAnimation];
}

- (void)enterForeground {
    [self.scanner startScanning];
    [self.scanView startAnimation];
}

- (LZScanner *)scanner {
    if (_scanner == nil) {
        
        _scanner = [[LZScanner alloc]initWithFrame:self.view.bounds];
        
        [self.view addSubview:_scanner];
    }
    
    return _scanner;
}

- (void)scanner:(LZScanner *)scanner didScanned:(NSString *)result {
    
    NSLog(@"扫描的结果: %@",result);
    [self.scanView stopAnimation];
    if (self.resultBlock) {
        self.resultBlock(result);
    }
    
    [self backButtonClick];
}

- (void)createScanView {
    
    LZScanView *scan = [[LZScanView alloc]initWithFrame:self.view.bounds];
    
    [self.view addSubview:scan];
    self.scanView = scan;
    
    self.scanner.scanArea = scan.windowRect;
}

- (void)customNaviBar {
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(10, 20, 60, 44);
    [backButton setImage:[UIImage imageNamed:reader_scan_btn_back_nor] forState:UIControlStateNormal];
    [backButton setImage:[UIImage imageNamed:reader_scan_btn_back_pressed] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    UIButton *libButton = [UIButton buttonWithType:UIButtonTypeCustom];
    libButton.center = CGPointMake(self.view.center.x, 44);
    libButton.bounds = CGRectMake(0, 0, 36, 44);
    
    [libButton setImage:[UIImage imageNamed:reader_scan_btn_photoDown] forState:UIControlStateHighlighted];
    [libButton setImage:[UIImage imageNamed:reader_scan_btn_photoNor] forState:UIControlStateNormal];
    [libButton addTarget:self action:@selector(openPhotoLib) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:libButton];
    
    
    UIButton *torchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    torchButton.frame = CGRectMake(self.view.frame.size.width - 46, 20, 36, 44);
    
    [torchButton setImage:[UIImage imageNamed:reader_scan_btn_flashOff] forState:UIControlStateSelected];
    [torchButton setImage:[UIImage imageNamed:reader_scan_btn_flashNor] forState:UIControlStateNormal];
    [torchButton setImage:[UIImage imageNamed:reader_scan_btn_flashDown] forState:UIControlStateHighlighted];
    [torchButton addTarget:self action:@selector(openTorch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:torchButton];
    
}
- (void)backButtonClick {
    if ([self.navigationController isKindOfClass:[UINavigationController class]]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)openPhotoLib {
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    
    controller.delegate = self;
    
    controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    //    controller.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:NULL];
}

- (void)openTorch:(UIButton*)button {
    button.selected = !button.selected;
    
    [LZScanner turnTorchOn:button.selected];
    
    
}

#pragma mark-> imagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //1.获取选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [LZScanner scanImage:image result:^(NSString *result) {
        
        NSLog(@"图片中的二维码: %@",result);
        if(self.resultBlock) {
            
            self.resultBlock(result);
        }
    }];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [self backButtonClick];
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
