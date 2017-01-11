//
//  LZScanConfigFiles.h
//  LZScaner
//
//  Created by Artron_LQQ on 2016/10/13.
//  Copyright © 2016年 Artup. All rights reserved.
//

#ifndef LZScanConfigFiles_h
#define LZScanConfigFiles_h

//判断是否是ipad
#define isIpad ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)

//判断是否是iphone4 (高度)
#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)

// imageName
static NSString *reader_scan_btn_back_nor = @"reader_scan_btn_back_nor";
static NSString *reader_scan_btn_back_pressed = @"reader_scan_btn_back_pressed";
static NSString *reader_scan_scanLine = @"reader_scan_scanLine";
static NSString *reader_scan_btn_flashDown = @"reader_scan_btn_flashDown";
static NSString *reader_scan_btn_flashNor = @"reader_scan_btn_flashNor";
static NSString *reader_scan_btn_flashOff = @"reader_scan_btn_flashOff";
static NSString *reader_scan_btn_photoDown = @"reader_scan_btn_photoDown";
static NSString *reader_scan_btn_photoNor = @"reader_scan_btn_photoNor";
static NSString *reader_scan_scanCamera = @"reader_scan_scanCamera";

static NSString *reader_scan_warnMsg = @"将二维码放入框内，即可自动扫描";
static NSString *reader_scan_Camera_warnMsg = @"没有使用相机权限,请到:\n\n\"设置-隐私-相机\"开启";
static NSString *reader_scan_noResultMsg = @"无内容";
#endif /* LZScanConfigFiles_h */
