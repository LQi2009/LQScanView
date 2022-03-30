//
//  LQRScanner.h
//  LQScanView
//
//  Created by 刘启强 on 2022/3/29.
//  Copyright © 2022 Q.ice. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LQRScannerDelegate ;
@interface LQRScanner : NSObject

@property (nonatomic, assign) BOOL lightDetectionEnable ;
@property (nonatomic, assign) NSInteger maxScanCount ;
@property (nonatomic) CGRect scanArea ;
@property (nonatomic) CGRect frame ;
@property (nonatomic, weak) id<LQRScannerDelegate> delegate ;
@property (nonatomic, strong) UIView *view;

- (void) startScanAsyncWithCompleteHandler:(void(^)(void)) handler ;
- (void) stopScanning ;

- (void) autoFocusScanCenter ;
+ (void)turnTorch:(BOOL) on ;
+ (BOOL)isCameraEnable ;
@end

@class LQRScanResult;
@protocol LQRScannerDelegate <NSObject>

- (void) scannerWillStartScanning:(LQRScanner *) scanner ;
- (void) scannerDidStartScanning:(LQRScanner *) scanner ;

- (void) scanner:(LQRScanner *) scanner didScanned:(NSArray<LQRScanResult *> *) results;
- (void) scanner:(LQRScanner *_Nonnull)scanner
    lightChanged:(CGFloat) value;
- (void) scannerCamaraDisable:(LQRScanner *_Nonnull)scanner;
- (void) scannerScanFailed:(LQRScanner *_Nonnull)scanner;

- (void) scannerDidEnterBackground:(LQRScanner *) scanner ;
- (void) scannerWillEnterForeground:(LQRScanner *) scanner ;

@end

@interface LQRScanResult : NSObject

@property (nonatomic, copy) NSString * result ;
@end
NS_ASSUME_NONNULL_END
