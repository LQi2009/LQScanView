//
//  ViewController.m
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+LongPress.h"
#import "LZScanViewController.h"
#import "LZScanner.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor greenColor];
    

    [self.imageView longPressScan:^(NSString *result) {
        NSLog(@"识别图片Block >%@",[NSThread currentThread]);
        
        self.label.text = result;
    }];
}

- (IBAction)beginScan:(id)sender {
    
    LZScanViewController *vc = [[LZScanViewController alloc]init];
    
//    [self presentViewController:vc animated:YES completion:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
    vc.resultBlock = ^(NSString *result) {
        
        NSLog(@"扫描block: %@",[NSThread currentThread]);
        
        self.label.text = result;
    };

}
- (IBAction)createQRCode:(id)sender {
    
    self.imageView.image = [LZScanner createQRcodeWith:self.textField.text];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self.view endEditing:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
