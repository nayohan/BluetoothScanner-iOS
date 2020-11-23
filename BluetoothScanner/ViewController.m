//
//  ViewController.m
//  Template
//
//  Created by MALAB on 2020/11/22.
//

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController {
    NSMutableArray* array;
    NSMutableArray* peripheralList;
    CBPeripheral* selectedPeripheral;
}
@synthesize tableView;
@synthesize centralManager;



/// 뷰 로드됌 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
    [super viewDidLoad];
    //array = [NSMutableArray arrayWithObjects:@"", nil];
    array = [NSMutableArray array];
    peripheralList = [NSMutableArray array];
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue: nil];
}



/// 테이블뷰 작동 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [array count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = [array objectAtIndex:indexPath.row];
    return cell;
}
// 3. 검색된 장치를 테이블에서 클릭했을때
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"indexPath.row: %ld", (long)indexPath.row);
    NSLog(@"peripheralList: %@", peripheralList);
    NSLog(@"array: %@", array);
    //기존 연결된 장치 끊기
    if(selectedPeripheral != nil && selectedPeripheral.state == CBPeripheralStateConnected){
        NSLog(@"3.0. Disconnect device: %@", selectedPeripheral.name);
        [centralManager cancelPeripheralConnection:selectedPeripheral];
    }
    //새로 선택한 장치 연결
    selectedPeripheral = (CBPeripheral*)peripheralList[indexPath.row];
    NSLog(@"3.1. Connect device: %@", selectedPeripheral.name);
    [centralManager connectPeripheral:selectedPeripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES}];
}



/// 블루투스 설정//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)startSearch:(id)sender { //미사용
    if (centralManager.state == CBManagerStatePoweredOn){
            NSLog(@"Start Search");
            //[_peripheralList removeAllObjects];
            [self.tableView reloadData];
            [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"0xFF00"]] options:nil];
            //UIBarButtonItem *stop = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopSearch:)];
            //self.navigationItem.rightBarButtonItem = stop;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    } else {
        [self ShowBluetoothSettingAlert];
    }
}
-(void)ShowBluetoothSettingAlert { //미사용
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *goOption = [UIAlertAction actionWithTitle:@"setting" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Bluetooth"] options:@{} completionHandler:nil];
    }];
}



/// 블루투스 연결 관리 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 4.블루투스가 클릭된 장치를 연결했을때 동작
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"4.Connected to %@, state: %ld", peripheral.name, (long)peripheral.state);
    peripheral.delegate = self; //delegate를 선언꼭! 이유는? CBPeripheralDelegate규약을 따름.
    [peripheral readRSSI]; //rssi불러오기
    [peripheral discoverServices:nil]; //서비스 불러오기
    
}
// 5.readRSSI함수를 실행했을때 동작
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    NSLog(@"5.RSSI: %@", RSSI);
}
// 6.discoverServices함수작동호 서비스를 찾았을때 동작
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error != nil) {
           NSLog(@"discoverServices error : peripheral: %@, error: %@",peripheral.name,error.debugDescription);
       } else { // 찾은 서비스를 선택해서 서비스내 특성 찾기
           for (CBService *service in peripheral.services) {
               NSLog(@"6.discoverd service : %@",service.debugDescription);
               //if([service.UUID.UUIDString isEqualToString:@"FFF0"]) {
                   [peripheral discoverCharacteristics:nil forService:service];
               //}
           }
       }
}
// 7.discoverCharacheristics함수작동 후 동작 -> 서비스에 대한 특성정보 찾았을때 동작
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *charater in service.characteristics) { //각각의 서비스에대해  특성을 구독
        NSLog(@"7.discovered Characteristic : %@ :%@", service ,charater.debugDescription);
        selectedPeripheral = peripheral;
        selectedPeripheral.delegate = self;
        [selectedPeripheral setNotifyValue:YES forCharacteristic:charater];
    }
}
// 8. 구독한 특성에 대해 측정기기가 데이터를 보내게 된다면 동작.
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSData* result = characteristic.value;
    if(result != nil) {
        NSLog(@"result:%@",result);
    }
}

// 2.블루투스가 장치를 찾았을때 동작
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([[NSString stringWithFormat:@"%@", peripheral.name] isEqual: @"(null)"]) return; //장치이름이 (null)인경우 Pass

    NSLog(@"2.Discovered %@ at %@", peripheral.name, RSSI);
    if ( [array containsObject:peripheral.name] != YES){ //테이블에 값이 없을때만 추가
        CBPeripheral *discovered = [peripheral copy];
        [peripheralList addObject:discovered];
        
        [array addObject:peripheral.name];
        [tableView reloadData];
    }
}
// 1.centralManager(블루투스) 상태가 stateOn 일때 장치검색 동작
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"Start scan");
    if(central.state == CBManagerStatePoweredOn){
        NSLog(@"1.Scanning for BTLE device");

        //특정 서비스의 UUID를 통해 장치를 찾는방법
        //NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber  numberWithBool:false], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        //CBUUID *myUUID = [CBUUID UUIDWithString:@"1809"];
        //[central scanForPeripheralsWithServices:[NSArray arrayWithObject:myUUID] options:options];
        
        //모든 장치를 찾는 방법
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}
@end
