//
//  ViewController.m
//  BPG-Bioland
//
//  Created by starlueng on 2016/8/10.
//  Copyright © 2016年 starlueng. All rights reserved.
//

#import "ViewController.h"
#import "BPGProtocol.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[BPGProtocol shareInstance]babyDelegate];
    
    NSArray *titles = @[@"开机",@"关机",@"上传一次数据",@"上传所有数据",@"开始测量",@"停止测量",@"设备时间改变",@"脉冲设置"];
    for (NSInteger i =0; i<8; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(100 *(i%3), 100*(i/3)+100, 100, 100);
        button.tag = 100+i;
        [self.view addSubview:button];
    }
  
    // Do any additional setup after loading the view, typically from a nib.
}
- (void) click:(UIButton *)sender{
    switch (sender.tag) {
        case 100:
        {
            [[BPGProtocol shareInstance]turnOnModeWith:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];
            [[BPGProtocol shareInstance]realTestMode:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];

        }
            break;
        case 101:
        {
            [[BPGProtocol shareInstance]turnOffModeWith:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];
        }
            break;
        case 102:
        {
            [[BPGProtocol shareInstance]getLastDataWith:^(BPGDataModel *model) {
                
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                
                NSLog(@"%@",error);
            }];
        }
            break;
        case 103:
        {
            [[BPGProtocol shareInstance]getAllTestDataWith:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];
        }
            break;
        case 104:
        {
            [[BPGProtocol shareInstance]realTestMode:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];
        }
            break;
        case 105:
        {
            [[BPGProtocol shareInstance]pauseMode:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];
        }
            break;
        case 106:
        {
            
            [[BPGProtocol shareInstance]setTimeWithTimeData:nil result:^(BPGDataModel *model) {
                
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                  NSLog(@"%@",error);
            }];
                    }
            break;
        case 107:
        {
            [[BPGProtocol shareInstance]isSendDeployWith:^(BPGDataModel *model) {
                NSLog(@"%@",model);
            } OrFail:^(NSError *error) {
                NSLog(@"%@",error);
            }];
        }
            break;
        default:
            break;
    }
    
   
    

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
