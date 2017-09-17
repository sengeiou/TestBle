//
//  BPGProtocol.m
//  BPG-Bioland
//
//  Created by starlueng on 2016/8/10.
//  Copyright © 2016年 starlueng. All rights reserved.
//


#import "BPGProtocol.h"
#import "MBProgressHUD.h"
#import "NSDate+SSToolkitAdditions.h"
static NSString *const channelOnCharacteristicView = @"babyDefault";
static NSString *const serverID                   = @"0000FBB0-494C-4F47-4943-544543480000";//服务器id
static NSString *const readCharacterID             = @"0000FBB1-494C-4F47-4943-544543480000";//读特征值
static NSString *const writeCharacterID            = @"0000FBB2-494C-4F47-4943-544543480000";//写特征值
@implementation BPGDataModel

@end
@implementation BPGProtocol

+ (instancetype) shareInstance{
    
    static BPGProtocol  *protocol = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        protocol = [[BPGProtocol alloc]init];
    });
    return protocol;
}
- (void)scanBleWithPrexName:(NSString *)prexName{
    //停止之前的连接
    [self.baby cancelAllPeripheralsConnection];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
    self.baby.scanForPeripherals().begin();
    
    __weak typeof(self) weakSelf = self;
    
    [self.baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"蓝牙已打开");
        }
    }];
    //1.设置查找设备的过滤器
    [self.baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        //最常用的场景是查找某一个前缀开头的设备
        if ([[peripheralName lowercaseString] hasPrefix:prexName] ) {
            
            NSLog(@"找到设备:%@",peripheralName);
            return YES;
        }
        return NO;
    }];
    
    //2.设置扫描到设备的委托
    [self.baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        if ([[peripheral.name lowercaseString] hasPrefix:prexName] ) {
            
            [weakSelf.baby cancelScan];
            weakSelf.currPeripheral = peripheral;
            MBProgressHUD *hud =[MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication]delegate]window ] animated:YES];
            [weakSelf connectBleWith:^(CBCharacteristic *writer, CBCharacteristic *read) {
                
                [hud hide:YES];
            }];
        }
    }];
    //3.扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES
                                     };
    //连接设备->
    [self.baby setBabyOptionsAtChannel:channelOnCharacteristicView scanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];

}
- (void)loadData{
    
    //4.开始连接设备
    self.baby.having(self.currPeripheral).and.channel(channelOnCharacteristicView).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
}
- (void)connectBleWith:(Block)success{
    //开始扫描设备
    [self performSelector:@selector(loadData) withObject:nil afterDelay:0.5];
    

    BabyRhythm *rhythm = [[BabyRhythm alloc]init];
    
    __weak typeof(self) weakSelf = self;
    
    //设置发现设service的Characteristics的委托
    [self.baby setBlockOnDiscoverCharacteristicsAtChannel:channelOnCharacteristicView block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===service name:%@",service.UUID);
        [rhythm beats];
    }];
    [self.baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"didDisconnectPeripheral-----%@",error);
        [weakSelf loadData];
    }];
    
    //设置读取characteristics的委托
    [self.baby setBlockOnReadValueForCharacteristicAtChannel:channelOnCharacteristicView block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        //获取设备的mac地址
        if ([characteristics.UUID.UUIDString isEqualToString:@"2A23"]) {
            
            weakSelf.information = characteristics.value;
        }
        if ([characteristics.UUID.UUIDString isEqualToString:writeCharacterID]) {
            
            weakSelf.writerCharacteristic = characteristics;
            
        }else if ([characteristics.UUID.UUIDString isEqualToString:readCharacterID]){
            weakSelf.readCharacteristic = characteristics;
            

        }
        if (weakSelf.writerCharacteristic&&weakSelf.readCharacteristic) {
            success(weakSelf.writerCharacteristic,weakSelf.readCharacteristic);
        }
        
    }];
    
    //设置写数据成功的block
    [self.baby setBlockOnDidWriteValueForCharacteristicAtChannel:channelOnCharacteristicView block:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"setBlockOnDidWriteValueForCharacteristicAtChannel characteristic:%@ and new value:%@",characteristic.UUID, characteristic.value);
    }];
   
}
//蓝牙网关初始化和委托方法设置
-(void)babyDelegate{
    //搜索蓝牙
    [self scanBleWithPrexName:@"serialcom"];
}

- (BabyBluetooth *)baby{
    
    if (!_baby) {
        
        _baby = [BabyBluetooth shareBabyBluetooth];
    }
    return _baby;
}

- (BPGDataModel *)transFormData:(NSData *)data{
    
    uint8_t packetData[data.length] ;
    memcpy(packetData, data.bytes, data.length);
    
   
    if (packetData[0] !=0x68) {
        
        return nil;
    }else{
        BPGDataModel *model = [[BPGDataModel alloc]init];
        model.head              = packetData[0];
        model.cmd               = packetData[1];
        model.status            = packetData[2];
        NSInteger bodyLength    = (packetData[4]<<8) +packetData[5];
        model.leng              = bodyLength;
        uint8_t bodys[bodyLength];
        memcpy(bodys, packetData+5, bodyLength);
        model.body              =[NSData dataWithBytes:&bodys length:bodyLength];
        model.checkcs           = packetData[data.length-2];
        model.end               = packetData[data.length-1];
        
        return model;
    }
}

-(void)writeValueWith:(NSData *)data AndNotifiy:(getResult)success OrFail:(getResult)fail{

    if (self.currPeripheral.state ==CBPeripheralStateConnected) {
        //写一个值
        [self.currPeripheral writeValue:data forCharacteristic:self.writerCharacteristic type:CBCharacteristicWriteWithResponse];
        //订阅一个值
        __weak typeof(self)weakSelf = self;
        if (!self.currPeripheral) {
            NSError *error = [NSError errorWithDomain:@"蓝牙设备未连接" code:0 userInfo:nil];
            fail(error);
           
            return;
        }
        if(self.currPeripheral.state != CBPeripheralStateConnected) {
            NSError *error = [NSError errorWithDomain:@"蓝牙已经断开连接，请重新连接" code:0 userInfo:nil];
            fail(error);

            return;
        }
        if (self.readCharacteristic.properties & CBCharacteristicPropertyNotify ||  self.readCharacteristic.properties & CBCharacteristicPropertyIndicate) {
            
            if(!self.readCharacteristic.isNotifying) {
                
                [weakSelf.currPeripheral setNotifyValue:YES forCharacteristic:self.readCharacteristic];
                
                [self.baby notify:self.currPeripheral
                   characteristic:self.readCharacteristic
                            block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                                NSLog(@"%@",characteristics.value);
                                BPGDataModel *model = [weakSelf transFormData:characteristics.value];
                                
                                success(model);
                            }];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:@"这个characteristic没有nofity的权限" code:0 userInfo:nil];
            fail(error);
           
            return;
        }
    }
}

- (void)babyStopConnect{

    [self.baby cancelScan];
    //蓝牙断开连接
    [self.baby cancelAllPeripheralsConnection];
}
@end
@implementation BPGProtocol (Commond)
- (NSData *)writeCommodDataWithcmd:(uint8_t)cmd Andcommond:(commond)common AndbodyData:(NSData *)body{
    NSInteger dataLength = 9+body.length;
    NSInteger bodyLength = 2+body.length;
    
    char byte[dataLength];
    memset(byte, 0, dataLength);
    byte[0] = 0x68;
    byte[1] = cmd;
    byte[3] = bodyLength%256;
    byte[4] = bodyLength/256;
    byte[5] = common>>8;
    byte[6] = common&0x00ff;
    if (body.length>0) {
        
        uint8_t bodys[body.length];
        memcpy(bodys, body.bytes, body.length);
        memcpy(byte+7, bodys, body.length);
    }

    NSInteger calibrate =0;
    for (NSInteger i=0; i<dataLength-2; i++) {
        calibrate += byte[i];
    }
    
    byte[dataLength-2] = calibrate&0xff;
    byte[dataLength-1] = 0x16;
    return [NSData dataWithBytes:byte length:dataLength];
}
- (void)getLastDataWith:(getResult )result OrFail:(getResult)fail{

    Byte bodyByte[] ={};
    
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:getLastTestData AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}
- (void)realTestMode:(getResult)result OrFail:(getResult)fail{
    Byte bodyByte[] ={};
    
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:realTestMode AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
         result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}
- (void)pauseMode:(getResult)result OrFail:(getResult)fail{
    Byte bodyByte[] ={};
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:pauseMode AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}
- (void)getAllTestDataWith:(getResult )result OrFail:(getResult)fail{
    Byte bodyByte[] ={};
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:getAllTestData AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];
}
- (void)turnOnModeWith:(getResult )result OrFail:(getResult)fail{
    Byte bodyByte[] ={};
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:turnOnMode AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}
- (void)turnOffModeWith:(getResult )result OrFail:(getResult)fail{
    Byte bodyByte[] ={};
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:turnOffMode AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}
- (void)setTimeWithTimeData:(NSString *)time result:(getResult )result OrFail:(getResult)fail{
    
    /*   如果不传time 默认设置时间为当前时间，如果传time则是设置时间   */
    NSData *valueData = [self writeCommodDataWithcmd:0x06 Andcommond:setTime AndbodyData:[self setTimeDataWith:nil]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}
- (void)isSendDeployWith:(getResult )result OrFail:(getResult)fail{
    Byte bodyByte[] ={};
    NSData *valueData = [self writeCommodDataWithcmd:0x02 Andcommond:isSendDeploy AndbodyData:[NSData dataWithBytes:bodyByte length:0]];
    [self writeValueWith:valueData AndNotifiy:^(BPGDataModel *model) {
        
        result(model);
    } OrFail:^(NSError *error) {
        fail(error);
    }];

}

- (NSData *)setTimeDataWith:(NSString *)timeStr{
    if (!timeStr) {
        timeStr = [[NSDate date]LocalTimeISO8601String];
    }
    
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"-: \n"];
    NSArray *timeArray = [timeStr componentsSeparatedByCharactersInSet:set];
    /* 获得的时间需要精确到秒 元素个数必须大于或者等于6 */
    assert(timeArray.count>=6);
    
    char timeByte[6];
    memset(timeByte, 0, 6);
    NSInteger year = [[timeArray firstObject]integerValue];
    year>1999?(year -= 2000):0;
    timeByte[0] = year;
    for (NSInteger i=1; i<6; i++) {
        
        timeByte[i] = [timeArray[i]integerValue];
    }
    return [NSData dataWithBytes:timeByte length:6];
}
@end