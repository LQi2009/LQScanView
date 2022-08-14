//
//  LQCamaraViewController.m
//  LQScanView
//
//  Created by 刘启强 on 2022/5/14.
//  Copyright © 2022 Q.ice. All rights reserved.
//

#import "LQCamaraViewController.h"
#import "LQCamara.h"

@interface LQCamaraViewController ()

@property (nonatomic, strong) LQCamara *camara;
@end

@implementation LQCamaraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];;
    self.camara.frame = self.view.bounds;
    
    [self.camara startScanning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (LQCamara *)camara {
    if (_camara == nil) {
        _camara = [[LQCamara alloc] init];
        [self.view addSubview:_camara];
    }
    return _camara;
}
@end
