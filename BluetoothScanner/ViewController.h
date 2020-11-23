//
//  ViewController.h
//  Template
//
//  Created by MALAB on 2020/11/22.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

//테이블뷰 딜리게이트, CB딜리게이트 추가
@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *thermoLabel;
@property (strong, nonatomic) CBCentralManager *centralManager;
@end

