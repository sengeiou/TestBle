//
//  BPGProtocol.swift
//  BPG-Bioland
//
//  Created by starlueng on 2016/8/12.
//  Copyright © 2016年 starlueng. All rights reserved.
//

import Foundation

enum commonds :UInt16{
    
    case getLastTestData
    case getAllTestData
    case realStateData
    case realTestData
    case realTestMode
    case pauseMode
    case turnOnMode
    case turnOffMode
    case  setTime
    case  getVersion
    case  isSendDeploy
    
    func simpleDescription() -> UInt16 {
        
        switch self {
            
        case .getLastTestData://上传最近一次测量结果命令
            return 0x1131
        case .getAllTestData://上传所有测量结果命令
            return 0x1331
        case .realStateData://时时上传状态数据
            return 0x0831
        case .realTestData://实时测量结果获取命令
            return 0x0931
        case .realTestMode://开始测量
            return 0x2131
        case .pauseMode://停止测量
            return 0x2231
        case .turnOnMode://开机
            return 0x0111
        case .turnOffMode://关机
            return 0x0211
        case .setTime://设置时间
            return 0x0331
        case .isSendDeploy://脉搏数据配置 1.发送 0.不发送
            return 0x0631
        default:
            return 0
        }
    }
    
};

let channelOnCharacteristicView : String = "babyDefault"
let serverID : String                    = "0000FBB0-494C-4F47-4943-544543480000"//服务器id
let readCharacterID : String             = "0000FBB1-494C-4F47-4943-544543480000"//读特征值
let writeCharacterID : String            = "0000FBB2-494C-4F47-4943-544543480000"//写特征值

struct thisCharacteristics {
    
   var write : CBCharacteristic , read :CBCharacteristic
}
class BPGProtocol: AnyObject {

    var baby : BabyBluetooth?,currPeripheral :CBPeripheral?,writerCharacteristic : CBCharacteristic? ,readCharacteristic : CBCharacteristic?,information : Data?
   
     init(){
        

    }
    
    func BLEDelegate()  {
        baby = BabyBluetooth.share()
        self.scanBleWithPrexName(prexName: "serialcom")
    }
    func scanBleWithPrexName(prexName :String) {
        
        //MARK:停止之前的连接
        baby!.cancelAllPeripheralsConnection()
        //MARK:设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
        baby!.scanForPeripherals()()?.begin()();
        
        baby!.setBlockOnCentralManagerDidUpdateState { (CBCentralManager) in
            
            if CBCentralManager?.state == .poweredOn{
            
                print("蓝牙已打开")
            }
        }
        //MARK:1.设置查找设备的过滤器
        baby!.setFilterOnDiscoverPeripherals { (peripheralName, advertisementData, RSSI) -> Bool in
            
            if (peripheralName?.lowercased().hasPrefix(prexName))!{
                
                return true
            }
            return false
        }
        //MARK:2.设置扫描到设备的委托
        baby!.setBlockOnDiscoverToPeripherals() { (central, peripheral, advertisementData, RSSI) in
            
            let peripheralName :String = peripheral!.name!
            if peripheralName.lowercased().hasPrefix(prexName){
            
                self.baby!.cancelScan()
                self.currPeripheral = peripheral
                let hud = MBProgressHUD.showAdded(to: UIApplication.shared.delegate!.window!, animated: true)
                
                self.connectBleWith(thisC: { (this :thisCharacteristics) in
                    
                    hud?.hide(true)
                })

            }
        }
    }
    
    func connectBleWith(thisC: @escaping (thisCharacteristics) ->())  {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { 
            self.loadData()
        }
        
        let rhythm = BabyRhythm.init()
        //MARK:设置发现设service的Characteristics的委托
        self.baby!.setBlockOnDiscoverCharacteristicsAtChannel(channelOnCharacteristicView, block: { (peripheral, service, error) in
            
            print("===service name:\(service?.uuid)")
            rhythm.beats()
        })
        self.baby!.setBlockOnDisconnect({ (central, peripheral, error) in
            
            print("didDisconnectPeripheral-----\(error)")
            self.loadData()
        })
        //MARK:设置读取characteristics的委托
        self.baby!.setBlockOnReadValueForCharacteristicAtChannel(channelOnCharacteristicView, block: { (peripheral, characteristics, error) in
            
            if characteristics?.uuid.uuidString == "2A23"{
                
                self.information = characteristics?.value!
            }
            if characteristics?.uuid.uuidString == writeCharacterID{
                
                self.writerCharacteristic = characteristics
            }else if  characteristics?.uuid.uuidString == readCharacterID{
                
                self.readCharacteristic = characteristics
            }
            if (self.readCharacteristic != nil) && (self.writerCharacteristic != nil){
                
                let character = thisCharacteristics(write: self.readCharacteristic! , read: self.writerCharacteristic!)
                
                
                thisC(character)
            }
        })
        //MARK:设置写数据成功的block
        self.baby!.setBlockOnDidWriteValueForCharacteristicAtChannel(channelOnCharacteristicView, block: { (characteristic, error) in
            
            print("setBlockOnDidWriteValueForCharacteristicAtChannel characteristic:%@ and new value:\(characteristic?.uuid, characteristic?.value)")
        })

    }
    @objc func loadData() -> Void {
        //MARK:4.开始连接设备
        
            self.baby!.having()(self.currPeripheral)?.and().channel()(channelOnCharacteristicView)?.then().connectToPeripherals()()?.discoverServices()()?.discoverCharacteristics()()?.readValueForCharacteristic()()?.discoverDescriptorsForCharacteristic()()?.readValueForDescriptors()()?.begin()();
    }
    //MARK:断开蓝牙连接
    func babyStopConnect()  {
        
        self.baby!.cancelScan()
        self.baby!.cancelAllPeripheralsConnection()
    }
    //MARK:解析获取的数据存储为model
    func transFormData(data :Data) -> BPGModel? {
        
        let leng = data.count
        var packetData :[UInt8] = [UInt8](repeating:0 ,count :leng)
        let dataStr = String.init(data: data , encoding: String.Encoding.utf8)
        var i = 0
        for ch in dataStr!.utf8 {
            
            packetData[i] = ch
            i += 1
        }
        if (packetData[0] != 0x68) {
            
            return nil;
        }else{
           let model = BPGModel()
            model.head              = packetData[0];
            model.cmd               = packetData[1];
            model.status            = packetData[2];
            let bodyLength          = (UInt16)((packetData[4] << 8) + packetData[5]);
            model.leng              = bodyLength;
            var bodys :[UInt8] = [UInt8](repeating:0 ,count : bodyLength.hashValue)
            for u in 6..<leng-2 {
                
                bodys[u] = packetData[u+6]
            }
            model.body              = bodys
            model.checkcs           = packetData[data.count-2];
            model.end               = packetData[data.count-1];
            
            return model;
        }

    }
    //MARK:发指令收取指令,返回
    func writeValueWith(data : NSData ,success: @escaping (BPGModel) -> (),fail:(NSError?) ->()) {

        if self.currPeripheral?.state == CBPeripheralState.connected {
            
            self.currPeripheral?.writeValue(data as Data, for: self.writerCharacteristic!, type: .withResponse)
            
            if self.currPeripheral == nil {
                
                let error = NSError.init(domain: "蓝牙设备未连接", code: 0, userInfo: nil)
                fail(error)
                return
            }
            if self.currPeripheral?.state != CBPeripheralState.connected {
                
                let error = NSError.init(domain: "蓝牙已经断开连接，请重新连接", code: 0, userInfo: nil)
                fail(error)
                return
            }
        }
        if self.readCharacteristic!.properties == CBCharacteristicProperties.notify || self.readCharacteristic!.properties == CBCharacteristicProperties.indicate {
            
            if ((self.readCharacteristic?.isNotifying) == nil) {
                
                self.currPeripheral?.setNotifyValue(true, for: self.readCharacteristic!)
                self.baby!.notify(self.currPeripheral!, characteristic: self.readCharacteristic!, block: { (peripheral, characteristics, error) in
                    let model = self.transFormData(data: characteristics!.value!)
                    success(model!)
                })
            }else{
            
                let error = NSError.init(domain: "这个characteristic没有nofity的权限", code: 0, userInfo: nil)
                fail(error)
                return
            }
            
        }
    
    }
    //MARK:编辑命令格式
    func writeCommodDataWithcmd(cmd:__uint8_t,common :commonds,body :[UInt8]) ->NSData {
        
        let dataLength = body.count + 9
        let bodyLength = body.count + 2
        var byte :[UInt8] = [UInt8].init(repeating: 0, count: dataLength)
        //(count: dataLength, repeatedValue: 0)
        byte[0] = 0x68;
        byte[1] = cmd;
        byte[3] = UInt8(bodyLength % 256) ;
        byte[4] = UInt8(bodyLength / 256);
        byte[5] = UInt8 (common.simpleDescription() >> 8);
        byte[6] = UInt8 (common.simpleDescription()&0x00ff);
        
        if body.count > 0 {
            
            let bodys = [UInt8].init(repeating: 0, count: body.count)
            for inc in 0 ..< body.count{
                
                
                byte[7+inc] = bodys[inc]
            }
        }
        var calibrate = 0
        for i in 0 ..< (dataLength - 2) {
            
            calibrate += byte[i].hashValue
        }
        byte[dataLength-2] = UInt8(calibrate&0xff)
        byte[dataLength-1] = 0x16
        
        return NSData.init(bytes: byte, length: dataLength)

    }
    //MARK:----------------------命令集=-------------------------------------
    func turnOnModeWith(success:(BPGModel) ->(),fail:(NSError) ->())  {//开机

        let bodyByte = [UInt8].init(repeating: 0, count: 0)
        let valueData = self.writeCommodDataWithcmd(cmd: 0x02, common: .turnOnMode, body: bodyByte)
        self.writeValueWith(data: valueData, success: { (model:BPGModel?) in
            
            print("\(model)")
        }) { (error:NSError?) in
            
                print("\(error)")
        }

    }
    
    func turnOffModeWith(success:(BPGModel) ->(),fail:(NSError) ->()) {//关机
        let bodyByte = [UInt8].init(repeating: 0, count: 0)
        let valueData = self.writeCommodDataWithcmd(cmd: 0x02, common: .turnOffMode, body: bodyByte)
        self.writeValueWith(data: valueData, success: { (model:BPGModel?) in
            
            print("\(model)")
        }) { (error:NSError?) in
            
            print("\(error)")
        }

    }
    func realTestMode(success:(BPGModel) ->(),fail:(NSError) ->()) {//开测
        
        let bodyByte = [UInt8].init(repeating: 0, count: 0)
        let valueData = self.writeCommodDataWithcmd(cmd: 0x02, common: .realTestMode, body: bodyByte)
        self.writeValueWith(data: valueData, success: { (model:BPGModel?) in
            
            print("\(model)")
        }) { (error:NSError?) in
            
            print("\(error)")
        }
        
    }
    func pauseMode(success:(BPGModel) ->(),fail:(NSError) ->()) {//暂停
        
        let bodyByte =  [UInt8].init(repeating: 0, count: 0)
        let valueData = self.writeCommodDataWithcmd(cmd: 0x02, common: .pauseMode, body: bodyByte)
        self.writeValueWith(data: valueData, success: { (model:BPGModel?) in
            
            print("\(model)")
        }) { (error:NSError?) in
            
            print("\(error)")
        }
    }

}
