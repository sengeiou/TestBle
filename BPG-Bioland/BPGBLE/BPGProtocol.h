//
//  BPGProtocol.h
//  BPG-Bioland
//
//  Created by starlueng on 2016/8/10.
//  Copyright © 2016年 starlueng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BabyBluetooth.h"
typedef void (^Block)(CBCharacteristic *writer,CBCharacteristic *read);
typedef void (^getResult)(id);
@interface BPGDataModel : NSObject

@property (assign,nonatomic) uint8_t   head;//起始码
@property (assign,nonatomic) uint8_t   cmd;//命令字
@property (assign,nonatomic) uint8_t   status;//状态字
@property (assign,nonatomic) uint16_t  leng;//包长度
@property (strong,nonatomic) NSData   *body;//内容部分
@property (assign,nonatomic) uint8_t   checkcs;//校验
@property (assign,nonatomic) uint8_t   end;//结束码
@end

typedef enum {
    
    getLastTestData = 0x1131,//上传最近一次测量结果命令
    getAllTestData  = 0x1331,//上传所有测量结果命令
    
    /* 时时上传状态数据 1.测量过程实时发送压力状态代码 2.测量完成 发送测量结果 */
    realStateData   = 0x0831,
    realTestData    = 0x0931,//实时测量结果获取命令
    
    startTest       = 0x2131,//开始一次测量
    stopTest        = 0x2231,//停止本次测量
    
    realTestMode    = 0x2131,//开始测量
    pauseMode       = 0x2231,//停止测量
    
    turnOnMode      = 0x0111,//开机
    turnOffMode     = 0x0211,//关机
    
    setTime         = 0x0331,//设置时间
    getVersion      = 0x0531,//读取设备型号
    
    isSendDeploy    = 0x0631,//脉搏数据配置 1.发送 0.不发送
}commond;


@interface BPGProtocol : NSObject

@property (strong,nonatomic) BabyBluetooth *baby;
@property (strong,nonatomic) CBPeripheral *currPeripheral;
@property (nonatomic,strong) CBCharacteristic *writerCharacteristic;
@property (nonatomic,strong) CBCharacteristic *readCharacteristic;
@property (nonatomic,strong) NSData *information;

+ (instancetype) shareInstance;
//设置蓝牙代理
- (void)babyDelegate;
//蓝牙断开连接
- (void)babyStopConnect;

-(void)writeValueWith:(NSData *)data AndNotifiy:(getResult)success OrFail:(getResult)fail;
@end
@interface BPGProtocol (Commond)

- (void)realTestMode:(getResult)result OrFail:(getResult)fail;//开始测量
- (void)pauseMode:(getResult)result OrFail:(getResult)fail;//停止测量
- (void)getLastDataWith:(getResult )result OrFail:(getResult)fail;//一次测量上传
- (void)getAllTestDataWith:(getResult )result OrFail:(getResult)fail;//所有测量上传
- (void)turnOnModeWith:(getResult )result OrFail:(getResult)fail;//开机
- (void)turnOffModeWith:(getResult )result OrFail:(getResult)fail;//关机
- (void)setTimeWithTimeData:(NSData *)time result:(getResult )result OrFail:(getResult)fail;//设置时间
- (void)isSendDeployWith:(getResult )result OrFail:(getResult)fail;//脉冲设置
@end