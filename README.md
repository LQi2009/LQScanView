###根据此OC版本,改写了一个Swift版本的[LZScanner_swift](https://github.com/LQQZYY/LZScanner_swift),欢迎star

#简介

二维码的功能经常使用,这里主要整理了是与二维码相关的一些操作

##功能
- 二维码扫描
- 相册选择图片识别二维码
- 长按图片识别二维码

##文件介绍
- LZScanner: 此类的作用是实现二维码的扫描及结果返回等相关的功能,独立于其他的文件,如果自定义了扫描界面,可单独使用;
- LZScanView: 此类定义了一个二维码扫描的界面,独立于其他文件,可单独使用;
- LZScanViewController: 此类是管理以上两个工具的使用,实现二维码扫描的界面及功能;
- LZScanConfigFiles :此文件定义了demo中所使用d到的一些资源名称,例如:图片名称,文字提示等;
- UIImageView+LongPress : 这个是为UIImageView扩展的类目,添加了一个方法,主要是实现图片长按识别其中二维码的功能,其中的识别功能依赖于LZScanner
- libqrencode : 这个是一个生成二维码的第三方类库,其中主要用了QRCodeGenerator这个类的方法,看其.h文件里d声明的方法即可明白;

其他的详细内容及用法,可以参看demo,里面都有详细的注释;
###如有问题,欢迎留言
###如果对你有帮助,请右上角star支持

