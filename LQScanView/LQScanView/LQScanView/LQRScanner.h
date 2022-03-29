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
@property (nonatomic) CGRect scanArea ;
@property (nonatomic, weak) id<LQRScannerDelegate> delegate ;

- (void) startScanningWithCompleteHandler:(void(^)(void)) handler ;
- (void) stopScanning ;

- (void) autoFocusScanCenter ;
+ (void)turnTorch:(BOOL) on ;
+ (BOOL)isCameraEnable ;
@end

@protocol LQRScannerDelegate <NSObject>

- (void) scannerWillStartScanning:(LQRScanner *) scanner ;
- (void) scannerDidStartScanning:(LQRScanner *) scanner ;
- (void) scannerIsScanning:(LQRScanner *) scanner ;
- (void) scannerStopScanning:(LQRScanner *) scanner ;
- (void) scannerDidEnterBackground:(LQRScanner *) scanner ;
- (void) scannerWillEnterForeground:(LQRScanner *) scanner ;

@end

NS_ASSUME_NONNULL_END
