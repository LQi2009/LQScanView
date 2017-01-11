//
//  LZScanView.m
//  LZScanner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#import "LZScanView.h"
#import "LZScanConfigFiles.h"

@interface LZScanView ()

@property (strong,nonatomic)LZScanOverlayView * overlayView;
@property (strong,nonatomic)UIImageView *cameraFrameView;
@property (strong,nonatomic)UIImageView *scanLineView;
@property (strong,nonatomic)UILabel *warnLabel;
@property (strong,nonatomic)UIActivityIndicatorView *activity;
@end

@implementation LZScanView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self loadSubViews];
    }
    return self;
}
- (void)dealloc {
    
    NSLog(@"dealloc");
}

#pragma mark - public method
- (void)startAnimation {
    
    if ([_activity isAnimating]) {
        [_activity stopAnimating];
    }
    
    [UIView animateKeyframesWithDuration:2 delay:0.0 options:UIViewKeyframeAnimationOptionRepeat animations:^{
        _scanLineView.center = CGPointMake(self.center.x, _cameraFrameView.frame.origin.y + _cameraFrameView.frame.size.height - 20);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)stopAnimation {
    
    [_scanLineView.layer removeAllAnimations];
    _scanLineView.center = CGPointMake(self.center.x, _cameraFrameView.frame.origin.y + 20);
}

- (CGRect)windowRect {
    
    return _cameraFrameView.frame;
}

#pragma mark - private method
- (void)loadSubViews {
    if (_overlayView == nil) {
        _overlayView = [[LZScanOverlayView alloc]initWithFrame:self.bounds];
        
        [self addSubview:_overlayView];
    }
    
    CGSize size = _overlayView.windowFrame.size;
    
    if (_cameraFrameView == nil) {
        _cameraFrameView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:reader_scan_scanCamera]];
        _cameraFrameView.center = _overlayView.windowCenter;
        
        _cameraFrameView.bounds = CGRectMake(0, 0, size.width + 8, size.height + 8);
        
        [self addSubview:_cameraFrameView];
    }
    
    if (_scanLineView == nil) {
        _scanLineView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:reader_scan_scanLine]];
        _scanLineView.center = CGPointMake(self.center.x, _cameraFrameView.frame.origin.y + 20);
        _scanLineView.bounds = CGRectMake(0, 0, _cameraFrameView.frame.size.width, 20);
        [self addSubview:_scanLineView];
    }
    
    if (_warnLabel == nil) {
        _warnLabel = [[UILabel alloc]init];
        _warnLabel.center = CGPointMake(self.center.x, _overlayView.windowCenter.y + _overlayView.windowFrame.size.height/2.0  + 40);
        //如果要显示在窗口中间位置,可这样设置
        //        _warnLabel.center = _overlayView.windowCenter;
        _warnLabel.bounds = CGRectMake(0, 0, self.bounds.size.width - 40, 20);
        _warnLabel.text = reader_scan_warnMsg;
        _warnLabel.textAlignment = NSTextAlignmentCenter;
        _warnLabel.font = [UIFont systemFontOfSize:14];
        _warnLabel.textColor = [UIColor whiteColor];
        [self addSubview:_warnLabel];
    }
    
    _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activity.center = _cameraFrameView.center;
    _activity.bounds = CGRectMake(0, 0, 50, 50);
    [self addSubview:_activity];
    
    [_activity startAnimating];
    
    [self performSelector:@selector(startAnimation) withObject:nil afterDelay:1];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@implementation LZScanOverlayView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.needsDisplayOnBoundsChange = YES;
    }
    return self;
}
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.layer.needsDisplayOnBoundsChange = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor colorWithWhite:0 alpha:0.7] setFill];
    [[UIColor colorWithWhite:0 alpha:0.7] setStroke];
    CGFloat smallestDimension = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGFloat windowSize = (isIpad ? 0.60:0.70)  * smallestDimension;
    
    CGFloat windowX = CGRectGetMidX(rect)- windowSize / 2.0;
    
    
    //导航高度 + 状态栏高度 + 距左右间距
    CGFloat windowY = 20 + 49 + (iPhone4 ? windowX/2.0 : windowX);
    
    //居中
    //    CGFloat windowY = CGRectGetMidY(rect) - windowSize/2.0;
    
    CGRect frame = CGRectMake(windowX, windowY, windowSize, windowSize);
    CGContextFillRect(context, rect);
    CGContextClearRect(context, frame);
    CGContextStrokeRect(context, frame);
}

- (CGPoint)windowCenter {
    
    CGFloat smallestDimension = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGFloat windowSize = (isIpad ? 0.60:0.70)  * smallestDimension;
    
    CGFloat windowX = CGRectGetMidX(self.frame)- windowSize / 2.0;
    
    //导航高度 + 状态栏高度 + 距左右间距
    CGFloat windowY = 20 + 49 + (iPhone4 ? windowX/2.0 : windowX);
    
    CGPoint point = CGPointMake(windowX + windowSize/2.0, windowY + windowSize/2.0);
    
    return point;
}

- (CGRect)windowFrame {
    
    CGFloat smallestDimension = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGFloat windowSize = (isIpad ? 0.60:0.70)  * smallestDimension;
    
    CGFloat windowX = CGRectGetMidX(self.frame)- windowSize / 2.0;
    
    //导航高度 + 状态栏高度 + 距左右间距
    CGFloat windowY =  20 + 49 + (iPhone4 ? windowX/2.0 : windowX);
    
    //居中
    //    CGFloat windowY = CGRectGetMidY(rect) - windowSize/2.0;
    
    CGRect frame = CGRectMake(windowX, windowY, windowSize, windowSize);
    
    return frame;
}
@end
