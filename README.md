### 根据此OC版本,改写了一个Swift版本的[LZScanner_swift](https://github.com/LQQZYY/LZScanner_swift),欢迎star

## 简介

主要文件有以下两个:

LQScanView: 封装了二维码扫描视图/动画和扫描识别二维码内容功能, 处理了进入后台, 从后台返回等情况;
LQRCoder: 封装了生成二维码/条形码, 识别图片中二维码内容, 保存生成的二维码等功能;
两个文件之间相互独立, 可根据需要分开使用;

LQScanViewController: 该类是基于上面两个文件实现的一个扫描页面控制器, 包含扫描二维码内容, 选择相册二维码图片进行识别, 识别周围光线亮度度提示是否开启灯光等功能; 可以直接使用, 也可以根据该示例, 根据需要布局自己的控制器视图;

## API 介绍

##### - LQScanView

该视图封装了扫描框, 扫描动画, 扫描识别二维码等功能, 通过代理方法回调相关事件; 对该视图的配置, 主要是通过相关的属性, 可以设置提示语, 扫描框及扫描线的名称:

```
/**
 提示文字
 默认为 '将二维码放入框内，即可自动扫描'
 */
@property (nonatomic, copy) IBInspectable NSString * warnText ;

/**
 扫描线图片名称
 默认为 'reader_scan_scanline'
 */
@property (nonatomic, copy) IBInspectable NSString * scanlineName ;
/**
 扫描框图片名称
 默认为 'reader_scan_scanCamera'
 */
@property (nonatomic, copy) IBInspectable NSString * scanframeName ;
​```
```

另外设置了一个最大扫描次数的限制, 当扫描一定次数, 未识别出二维码内容时, 可以根据需要设置提示等:

```
/**
 最大识别次数, 当识别次数达到该值,仍未识别出结果时停止扫描
 通过 scanViewScanFailed: 回调
 默认为 0,不限制
 */
@property (nonatomic, assign) IBInspectable NSUInteger maxScanCount 
```

对于扫描区域, 直接设置在视图中的坐标即可, 内部实现了有效坐标的转换, 当值为 CGRectZero 时, 可全屏都是识别区域

```
/**
 扫描区域, 默认屏幕宽*0.7, 最大300, 居中
 当为 CGRectZero 的时候, 全屏扫描
 */
@property (nonatomic) IBInspectable CGRect scanArea ;
```



针对扫描框和提示文本的位置, 我定义了相应的枚举, 可通过下面的属性进行设置:

```
/**
 提示文字的位置
 */
@property (nonatomic, assign) LQWarnTextAlignment warnTextAlignment ;

/**
 扫描框的位置
 */
@property (nonatomic, assign) LQScanframeType scanframeType ;
```



在需要使用检测当前环境光线亮度功能时, 需要设置属性 `lightDetectionEnable`为 `YES`:

```
/**
 是否检测当前环境光线强度, 通过代理 'scanView:lightChanged:' 反馈
 默认不检测
 */
@property (nonatomic, assign) IBInspectable BOOL lightDetectionEnable
```



同时, 个别属性支持通过 `XIB` 进行设置;

相对来说, 定义的方法, 根据需要调用即可, 开始/结束的方法, 使用时可不调用, 内部进行了处理:

```
/**
 开始扫描
 */
- (void) startScanning ;
- (void) startAnimate;

/**
 停止扫描
 */
- (void) stopScanning ;
- (void) stopAnimate ;

/**
 聚焦
 */
- (void) autoFocusScanCenter ;

/**
 打开闪光灯

 @param on YES: 打开; NO: 关闭
 */
+ (void)turnTorch:(BOOL) on ;

/**
 是否有相机权限

 @return YES or NO
 */
+ (BOOL)isCameraEnable ;
```



##### - LQRCoder

该类是对 `LQScanView` 的一个补充, 定义了生成二维码/条形码, 识别图片中的二维码信息等方法:

```
/**
 识别图片二维码中的信息
 
 @param image 含有二维码的图片
 @param handler 二维码信息
 */
+ (void)scanQRImage:(UIImage * _Nullable)image
      resultHandler:(void(^)(NSArray * _Nullable results))handler ;

/**
 生成二维码图片
 
 @param content 二维码中的信息, NSString 类型，或者 NSData
 @param size 二维码大小
 @param color 二维码颜色
 @param bgColor 二维码背景色
 @param logo 中心logo
 @param logoSize logo 尺寸
 @return 二维码图片
 */
+ (UIImage*)QRImageWithContent:(id)content
                        qrSize:(CGFloat)size
                     tintColor:(UIColor * _Nullable)color
               backgroundColor:(UIColor* _Nullable)bgColor
                          logo:(UIImage* _Nullable)logo
                      logoSize:(CGFloat)logoSize ;

/**
 生成条形码
 
 @param content 条形码的内容，NSString 类型，或者 NSData
 @param size 条形码大小
 生成的条形码在显示在UIImageView的时候, 其size至少有一个值要大于 UIImageView 的size,否则,会显示模糊'
 建议将 UIImageView 的size传入
 @param color 条形码颜色
 @param bgcolor 条形码背景色
 @return 条形码图片
 */
+ (UIImage *)BarImageWithContent:(NSString *)content
                         barSize:(CGSize)size
                       tintColor:(UIColor *_Nullable)color
                 backgroundColor:(UIColor *_Nullable)bgcolor ;
```

同时提供了异步生成的方法, 根据需要选择使用;



另外, 对于需要保存生成的二维码的需求, 生成的图片, 不能直接使用 `UIImageJPEGRepresentation` 进行转换保存, 这里我定义了下面的方法来进行保存:

```
/**
 将生成的CIImage 以jpg格式保存到某个URL
 
 @param url 文件地址
 当为nil时保存至相册, 需要在Info.plist添加 NSPhotoLibraryAddUsageDescription
 @param image CIImage
 @return 是否保存成功
 */
UIKIT_EXTERN BOOL LQCIImageSavedJPEGToURL(NSURL * _Nullable url, CIImage * _Nonnull image);
UIKIT_EXTERN BOOL LQImageSavedJPEGToURL(NSURL * _Nullable url, UIImage * _Nonnull image);

/**
 将生成的CIImage 转换为JPEG的NSData
 
 @param image CIImage
 @return NSData
 */
UIKIT_EXTERN NSData * _Nullable LQJPEGDataFromCIImage(CIImage * _Nonnull image) ;
UIKIT_EXTERN NSData * _Nullable LQJPEGDataFromUIImage(UIImage * _Nonnull image) ;
```



## 使用示例

更多的使用, 可参考 `LQScanViewController`



```
- (LQScanView *)scanView {
    if (_scanView == nil) {
        _scanView = [[LQScanView alloc]initWithFrame:self.view.bounds];
        _scanView.delegate = self;
        _scanView.lightDetectionEnable = YES;
        _scanView.scanArea = CGRectZero;
        [self.view addSubview:_scanView];
    }
    
    return _scanView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.scanView.frame = self.view.bounds;
}
```



识别图片中二维码/条形码:

```
 [LQRCoder scanQRBarImage:image resultHandler:^(NSArray * _Nullable results) {
            
            if (self.completeHandler) {
                self.completeHandler([results firstObject]);
            }
        }];
```



生成二维码/条形码:

同步生成

```
NSString *t = self.textField.text;
    
//   self.imageView.image = [LQScanView QRImageWithContent:t];
self.imageView.image = [LQRCoder QRImageWithContent:t qrSize:400 tintColor:[UIColor blackColor] backgroundColor:[UIColor whiteColor] logo:[UIImage imageNamed:@"test"] logoSize:100];
```

异步生成

```
NSString *t = self.textField.text;
[LQRCoder QRImageAsyncWithContent:t completeHandler:^(UIImage * _Nonnull image) {
        self.imageView.image = image;
    }];
```
## 效果图


![正常扫描](https://github.com/LQi2009/LQScanView/blob/master/scanTest.jpeg)



![光线较暗的情况](https://github.com/LQi2009/LQScanView/blob/master/scanTest1.jpeg)

### 如有问题,欢迎留言
### 如果对你有帮助,请右上角star支持

