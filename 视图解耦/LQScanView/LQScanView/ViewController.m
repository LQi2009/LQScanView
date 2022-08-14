//
//  ViewController.m
//  LQScanView
//
//  Created by LiuQiqiang on 2019/4/15.
//  Copyright © 2019 Q.ice. All rights reserved.
//

#import "ViewController.h"
#import "LQRCoder.h"
#import "UIImageView+LongPress.h"
#import "LQScanViewController.h"
#import "LQCamaraViewController.h"
#import "RBScanViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController
- (IBAction)makeQR:(id)sender {
    NSString *t = self.textField.text;
    
//    self.imageView.image = [LQScanView QRImageWithContent:t];
//    self.imageView.image = [LQRCoder QRImageWithContent:t qrSize:400 tintColor:[UIColor blackColor] backgroundColor:[UIColor whiteColor] logo:[UIImage imageNamed:@"test"] logoSize:100];
    [LQRCoder QRImageAsyncWithContent:t completeHandler:^(UIImage * _Nonnull image) {
        self.imageView.image = image;
    }];
}
- (IBAction)makeBar:(id)sender {
//    self.imageView.image = [LQScanView BarImageWithContent:self.textField.text size:CGSizeMake(100, 61.8) tintColor:[UIColor orangeColor] backgroundColor:[UIColor blackColor]];
//    self.imageView.image = [LQRCoder BarImageWithContent:self.textField.text];
//    [LQRCoder ];
    
    NSData *data = UIImageJPEGRepresentation(self.imageView.image, 1.0);
    LQCIImageSavedJPEGToURL(nil, self.imageView.image.CIImage);
    
//    self.imageView.image = [LQScanView BarImageWithContent:@"2222222" size:CGSizeMake(100, 400) tintColor:nil backgroundColor:nil];
//    [self generateCodeWithImageView:self.imageView code:@"ddddddddd"];
}
- (IBAction)takePhoto:(id)sender {
    
    LQCamaraViewController *camara = [[LQCamaraViewController alloc] init];
    [self.navigationController pushViewController:camara animated:YES];
}
- (IBAction)scanQR:(id)sender {
    
    RBScanViewController *rbscan = [[RBScanViewController alloc] init];
    [self.navigationController pushViewController:rbscan animated:YES];
    return;
    LQScanViewController *scan = [[LQScanViewController alloc]init];
    [self.navigationController pushViewController:scan animated:YES];
    [scan didScanedWithCompleteHandler:^(id  _Nonnull info) {
        self.label.text = info;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.imageView longPressScan:^(NSString *result) {
        self.label.text = result;
    }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"%@", NSStringFromCGSize(size));
    
//    __scanView.frame = CGRectMake(0, 0, size.width, size.height);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
@end
