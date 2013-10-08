//
//  ViewController.h
//  testBluetoothConnection
//
//  Created by 王權 on 13/8/12.
//  Copyright (c) 2013年 王權. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *peripheralName;
@property (strong, nonatomic) IBOutlet UIButton *startScanning;
@property (strong, nonatomic) IBOutlet UILabel *rssi;
@property (strong, nonatomic) IBOutlet UILabel *serviceUUID;
@property (strong, nonatomic) IBOutlet UILabel *connectedOrNot;
@property (strong, nonatomic) IBOutlet UILabel *characteristicValue;

- (IBAction)scanButton:(id)sender;

@end

@interface sensorTMP006 : NSObject
+(float) calcTAmb:(NSData *)data;
+(float) calcTAmb:(NSData *)data offset:(int)offset;
+(float) calcTObj:(NSData *)data;
@end