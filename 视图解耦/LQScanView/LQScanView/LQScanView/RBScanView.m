//
//  RBScanView.m
//  RBScanView
//
//  Created by NewTV on 2022/3/31.
//  Copyright © 2022 Q.ice. All rights reserved.
//

#import "RBScanView.h"
#import "LQRScanner.h"

@interface RBScanView ()<LQRScannerDelegate>{
    
    UIInterfaceOrientation __currentOrientation;
    BOOL __isAnimating;
}

@property (nonatomic, strong) UIImageView * scanLine ;
@property (nonatomic, strong) UIView * overlayView ;
@property (nonatomic, strong) UILabel * textLabel ;
@property (nonatomic, strong) UIImageView * scanImageView ;
@property (nonatomic, strong) UIActivityIndicatorView * activity ;
@property (nonatomic, strong) UIButton * lightButton ;
@property (nonatomic, strong) LQRScanner * scanner ;
@end
@implementation RBScanView

- (void)dealloc {
    
    [self stopAnimate];
    
    NSLog(@"LQRScanOverlayView dealloc");
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepare];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self prepare];
    }
    return self;
}

- (void) showActivity {
    self.activity.hidden = NO;
    [self.activity startAnimating];
}

- (void) hiddenActivity {
    [self.activity stopAnimating];
}

- (void) startScan {
    [self startAnimate];
//    [self.scanner startScanning];
}

- (void) stopScan {
    [self stopAnimate];
    [self.scanner stopScanning];
}

- (void) startAnimate {
    if (__isAnimating) {
        return;
    }
    __isAnimating = YES;
    self.scanLine.hidden = NO;
    
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationMove setFromValue:[NSNumber numberWithFloat:4]];
    [animationMove setToValue:[NSNumber numberWithFloat:CGRectGetHeight(self.scanArea) - 8]];
    animationMove.duration = 2;
    animationMove.repeatCount  = MAXFLOAT;
    animationMove.fillMode = kCAFillModeForwards;
    animationMove.removedOnCompletion = NO;
    animationMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [self.scanLine.layer addAnimation:animationMove forKey:@"lineMove"];
}

- (void) stopAnimate {
    if (__isAnimating == NO) {
        return;
    }
    __isAnimating = NO;
    [self.scanLine.layer removeAllAnimations];
    self.scanLine.hidden = YES;
}

- (void)setMaxScanCount:(NSInteger)maxScanCount {
    _maxScanCount = maxScanCount;
    self.scanner.maxScanCount = maxScanCount;
}

- (void)setScanArea:(CGRect)scanArea {
    _scanArea = scanArea;
    self.scanner.scanArea = scanArea;
}

+ (void)turnTorch:(BOOL) on {
    [LQRScanner turnTorch:on];
}

+ (BOOL)isCameraEnable {
    return [LQRScanner isCameraEnable];
}

- (void)scanner:(LQRScanner *)scanner didScanned:(NSArray<LQRScanItem *> *)results {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(scanView:didScanned:)]) {
        
        NSMutableArray *m_arr = [NSMutableArray arrayWithCapacity:results.count];
        for (LQRScanItem *item in results) {
            RBScanResult *res = [[RBScanResult alloc] init];
            res.result = item.result;
            [m_arr addObject:res];
        }
        
        [self.delegate scanView:self didScanned:[m_arr copy]];
    }
}

- (void)scanner:(LQRScanner *)scanner statusChanged:(LQRScannerStatus)status {
    
    NSString *msg = @"";
    switch (status) {
        case LQRScannerWillStartSession:
            // 启动的时候，会有2s左右的耗时，
            msg = @"LQRScannerWillStartSession";
            [self showActivity];
            break;
        case LQRScannerDidStartSession:
            msg = @"LQRScannerDidStartSession";
            [self hiddenActivity];
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
    
    NSLog(@"%@", msg);
}


- (void) scanner:(LQRScanner *)scanner lightChanged:(CGFloat)value {
    NSLog(@"lightChanged %f", value);
    BOOL isShow = value > -1 ? NO: YES;
    if (isShow) {
        if (self.lightButton.alpha  == 0) {
            [self showLightbutton:isShow];
        }
    } else {
        if (self.lightButton.alpha  > 0) {
            [self showLightbutton:isShow];
        }
    }
}

- (void)scannerScanFailed:(LQRScanner *)scanner {
    if (self.delegate && [self.delegate respondsToSelector:@selector(scanViewScanFailed:)]) {
        [self.delegate scanViewScanFailed:self];
    }
}

- (void) showLightbutton:(BOOL) show {
    
    if (show) {
        if (self.lightButton.alpha > 0) {
            return;
        }
        
        [self stopAnimate];
        [UIView animateWithDuration:0.5 animations:^{
            self.lightButton.alpha = 1.0;
        }];
    } else {
        [self startAnimate];
        if (self.lightButton.selected == NO) {
            self.lightButton.alpha = 0;
        }
    }
}

- (void) lightButtonAction:(UIButton *) button {
    button.selected = !button.selected;
    [RBScanView turnTorch:button.selected];
}

#pragma mark -
- (void) prepare {
    
    self.backgroundColor = [UIColor blackColor];
    
    _scanframeType = RBScanViewframeTypeOn;
    _warnTextAlignment = RBScanViewWarnTextAlignmentBottom;
    _warnText = @"将二维码放入框内，即可自动扫描";
    _scanlineName = @"reader_scan_scanline";
    _scanframeName = @"reader_scan_scanCamera";
    
    CGRect f = [UIScreen mainScreen].bounds;
    CGFloat w = f.size.width < f.size.height ? f.size.width: f.size.height;
    w *= 0.7;
    if (w > 300) {
        w = 300;
    }
    
    CGFloat x = (CGRectGetWidth(f) - w) / 2.0;
    CGFloat y = (CGRectGetHeight(f) - w) / 2.0;
    self.scanArea = CGRectMake(x, y, w, w);
}

- (void) resetOverlay {
    
    UIInterfaceOrientation deviceOri = [UIApplication sharedApplication].statusBarOrientation;
    
    if (__currentOrientation == deviceOri) {
        return;
    }
    
    __currentOrientation = deviceOri;

    
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    
    UIBezierPath *centerPath = [UIBezierPath bezierPathWithRect:self.scanArea];
    [path appendPath:centerPath];
    
    CAShapeLayer *overlay = [CAShapeLayer layer];
    overlay.path = path.CGPath;
    overlay.fillRule = kCAFillRuleEvenOdd;
    self.overlayView.layer.mask = overlay;
    
    [self startAnimate];
}

#pragma mark -
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.overlayView.frame = self.bounds;
    self.scanner.scanArea = self.scanArea;
    self.scanner.frame = self.bounds;
    self.lightButton.bounds = CGRectMake(0, 0, 100, 100);
    self.lightButton.center = self.center;
    
    if (self.warnTextAlignment == RBScanViewWarnTextAlignmentTop) {
        self.textLabel.frame = CGRectMake(20, CGRectGetMinY(self.scanArea) - 40, CGRectGetWidth(self.bounds) - 40, 30);
    } else if (self.warnTextAlignment == RBScanViewWarnTextAlignmentCenter) {
        self.textLabel.frame = CGRectMake(20, CGRectGetMidY(self.scanArea), CGRectGetWidth(self.bounds) - 40, 30);
    } else {
        self.textLabel.frame = CGRectMake(20, CGRectGetMaxY(self.scanArea) + 10, CGRectGetWidth(self.bounds) - 40, 30);
    }
    
    UIInterfaceOrientation ori = [UIApplication sharedApplication].statusBarOrientation;
    if (ori != UIInterfaceOrientationPortrait && ori != UIInterfaceOrientationPortraitUpsideDown) {
        
        if (CGRectGetMaxY(self.textLabel.frame) > CGRectGetHeight(self.frame)) {
            self.textLabel.frame = CGRectMake(20, CGRectGetMidY(self.scanArea), CGRectGetWidth(self.bounds) - 40, 30);
        }
    }
    
    if (self.scanframeType == RBScanViewframeTypeOn) {
        self.scanImageView.frame = self.scanArea;
    } else if (self.scanframeType == RBScanViewframeTypeOut) {
        
        self.scanImageView.frame = CGRectInset(self.scanArea, -4, -4);
    } else {
        self.scanImageView.frame = CGRectInset(self.scanArea, 2, 2);
    }
    
    self.scanLine.bounds = CGRectMake(0, 0, self.scanArea.size.width - 4, 2);
    self.scanLine.center = CGPointMake(CGRectGetMidX(self.scanArea), self.scanArea.origin.y + 4);
    self.activity.center = CGPointMake(CGRectGetMidX(self.scanArea), CGRectGetMidY(self.scanArea));
    
    [self resetOverlay];
}

- (LQRScanner *)scanner {
    if (_scanner == nil) {
        _scanner = [[LQRScanner alloc] init];
        _scanner.delegate = self;
        _scanner.lightDetectionEnable = YES;
        [self.layer insertSublayer:_scanner.layer atIndex:0];
    }
    
    return _scanner;
}

- (UIImageView *)scanLine {
    if (_scanLine == nil) {
        _scanLine = [[UIImageView alloc]initWithImage:[UIImage imageNamed:self.scanlineName]];
        [self addSubview:_scanLine];
    }
    
    return _scanLine;
}

- (UIImageView *)scanImageView {
    if (_scanImageView == nil) {
        UIImage *img = [UIImage imageNamed:self.scanframeName];
        img = [img stretchableImageWithLeftCapWidth:img.size.width/2.0 topCapHeight:img.size.height/2.0];
        
        _scanImageView = [[UIImageView alloc]initWithImage:img];
        
        [self addSubview:_scanImageView];
    }
    return _scanImageView;
}

- (UILabel *)textLabel {
    if (_textLabel == nil) {
        _textLabel = [[UILabel alloc]init];
        _textLabel.text = self.warnText;
        _textLabel.font = [UIFont systemFontOfSize:14];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        [self addSubview:_textLabel];
    }
    
    return _textLabel;
}

- (UIActivityIndicatorView *)activity {
    if (_activity == nil) {
        _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhite)];
        [self addSubview:_activity];
    }
    
    return _activity;
}

- (UIView *)overlayView {
    if (_overlayView == nil) {
        
        _overlayView = [[UIView alloc]init];
        _overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self addSubview:_overlayView];
    }
    
    return _overlayView;
}

- (UIButton *)lightButton {
    if (_lightButton == nil) {
        _lightButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_lightButton setImage:[UIImage imageNamed:@"light_close"] forState:(UIControlStateNormal)];
        _lightButton.alpha = 0;
        [_lightButton setImage:[UIImage imageNamed:@"light_open"] forState:(UIControlStateSelected)];
        [_lightButton addTarget:self action:@selector(lightButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:_lightButton];
    }
    
    return _lightButton;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@implementation RBScanResult
@end
