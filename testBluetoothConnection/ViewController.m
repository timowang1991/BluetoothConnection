//
//  ViewController.m
//  testBluetoothConnection
//
//  Created by 王權 on 13/8/12.
//  Copyright (c) 2013年 王權. All rights reserved.
//

#import "ViewController.h"
#import <math.h>
#define sensorTag [CBUUID UUIDWithString:@"f000aa00-0451-4000-b000-000000000000"]
#define IR_Temp_Service [CBUUID UUIDWithString:@"f000aa00-0451-4000-b000-000000000000"]
#define IR_Temp_Char [CBUUID UUIDWithString:@"f000aa01-0451-4000-b000-000000000000"]
#define IR_Temp_Config [CBUUID UUIDWithString:@"f000aa02-0451-4000-b000-000000000000"]

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBCentralManager * centralManager;
@property (strong, nonatomic) NSMutableArray * nPeripherals;

@end

@implementation ViewController

@synthesize centralManager;
@synthesize nPeripherals;
@synthesize peripheralName;
@synthesize startScanning;
@synthesize rssi;
@synthesize serviceUUID;
@synthesize connectedOrNot;
@synthesize characteristicValue;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"viewDidLoad finish");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        NSLog(@"scanForPeripheralsWithServices");
    }
    else{
        [self.nPeripherals removeAllObjects];
        NSLog(@"nPeripherals objects all removed");
    }
    NSLog(@"centralManagerDidUpdateState finish");
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    NSLog(@"didDiscoverPeripheral");
    if(![self.nPeripherals containsObject:peripheral]){
        [self.nPeripherals addObject:peripheral];
        NSLog(@"Discovered potential peripheral %@", peripheral);
        peripheralName.text = peripheral.name;
        rssi.text = [NSString stringWithFormat:@"%@",RSSI];
        connectedOrNot.text = [NSString stringWithFormat:peripheral.isConnected ? @"connected":@"not connected"];
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"Failed to connect peripheral %@ (%@)", peripheral, error);
    connectedOrNot.text = [NSString stringWithFormat:peripheral.isConnected ? @"connected":@"not connected"];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"Disconnected peripheral %@ (%@)",peripheral, error);
    connectedOrNot.text = [NSString stringWithFormat:peripheral.isConnected ? @"connected":@"not connected"];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //Discover service
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    connectedOrNot.text = [NSString stringWithFormat:peripheral.isConnected ? @"connected":@"not connected"];
    NSLog(@"didConnectPeripheral");
}

#pragma mark - Peripheral delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"peripheralDidDiscoverServices");
    if (!error) {
        NSLog(@"peripheralDidDiscoverServices no error");
        for (CBService * service in peripheral.services) {
            if([service.UUID isEqual:sensorTag]){
                NSLog(@"service.UUID isEqual to IR_Temp_Service");
                //Discover the characteristic
                [peripheral discoverCharacteristics:@[IR_Temp_Char] forService:service];
                return;
            }
        }
    }
    
    [self.centralManager cancelPeripheralConnection:peripheral];
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (!error) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            if([characteristic.UUID isEqual:IR_Temp_Char]){
                //Subscribe to updates of the heart rate characteristic
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [self.centralManager stopScan];
                NSLog(@"characteristic.UUID isEqual to IR_Temp_Char");
            }
            
            //turn on the IR sensor
            if ([characteristic.UUID isEqual:IR_Temp_Config]) {
                uint8_t data = 0x01;
                [peripheral writeValue:[NSData dataWithBytes:&data length:1] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                return;
            }
        }
    }
    
    [self.centralManager cancelPeripheralConnection:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"didUpdateNotificationStateForCharacteristic");
    if (error) {
        NSLog(@"Failed to subscribe to peripheral %@ (%@)",peripheral, error);
        [self.centralManager cancelPeripheralConnection:peripheral];
        return;
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //Received updated data
    float tObj = [sensorTMP006 calcTObj:characteristic.value];
    NSLog(@"Received updated data from peripheral");
    connectedOrNot.text = [NSString stringWithFormat:peripheral.isConnected ? @"connected":@"not connected"];
    characteristicValue.text = [NSString stringWithFormat:@"%f",tObj];
}

- (IBAction)scanButton:(id)sender {
    self.centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.nPeripherals = [NSMutableArray new];
}
@end

@implementation sensorTMP006
//IR data conversion

+(float) calcTAmb:(NSData *)data {
    char scratchVal[data.length];
    int16_t ambTemp;
    [data getBytes:&scratchVal length:data.length];
    ambTemp = ((scratchVal[2] & 0xff)| ((scratchVal[3] << 8) & 0xff00));
    
    return (float)((float)ambTemp / (float)128);
}

+(float) calcTAmb:(NSData *)data offset:(int)offset {
    char scratchVal[data.length];
    int16_t ambTemp;
    [data getBytes:&scratchVal length:data.length];
    ambTemp = ((scratchVal[offset] & 0xff)| ((scratchVal[offset + 1] << 8) & 0xff00));
    
    return (float)((float)ambTemp / (float)128);
}


+(float) calcTObj:(NSData *)data {
    char scratchVal[data.length];
    int16_t objTemp;
    int16_t ambTemp;
    [data getBytes:&scratchVal length:data.length];
    objTemp = (scratchVal[0] & 0xff)| ((scratchVal[1] << 8) & 0xff00);
    ambTemp = ((scratchVal[2] & 0xff)| ((scratchVal[3] << 8) & 0xff00));
    
    float temp = (float)((float)ambTemp / (float)128);
    long double Vobj2 = (double)objTemp * .00000015625;
    long double Tdie2 = (double)temp + 273.15;
    long double S0 = 6.4*pow(10,-14);
    long double a1 = 1.75*pow(10,-3);
    long double a2 = -1.678*pow(10,-5);
    long double b0 = -2.94*pow(10,-5);
    long double b1 = -5.7*pow(10,-7);
    long double b2 = 4.63*pow(10,-9);
    long double c2 = 13.4f;
    long double Tref = 298.15;
    long double S = S0*(1+a1*(Tdie2 - Tref)+a2*pow((Tdie2 - Tref),2));
    long double Vos = b0 + b1*(Tdie2 - Tref) + b2*pow((Tdie2 - Tref),2);
    long double fObj = (Vobj2 - Vos) + c2*pow((Vobj2 - Vos),2);
    long double Tobj = pow(pow(Tdie2,4) + (fObj/S),.25);
    Tobj = (Tobj - 273.15);
    return (float)Tobj;
}

@end
