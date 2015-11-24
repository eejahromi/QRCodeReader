//
//  ViewController.m
//  CodeReader
//
//  Created by Ehsan on 10/31/15.
//  Copyright © 2015 Ehsan Jahromi. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate,UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) NSDictionary *information;
@property (strong,nonatomic) NSDictionary *products;
@property (strong,nonatomic) NSArray *ingredients;
@end

@implementation ViewController{
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    UIView *qrCodeFrameView;
    BOOL tableViewShowing;
    __block NSString *previousUrl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor darkGrayColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.hidden = YES;
    previousUrl = [NSString string];
    
    self.information = [NSDictionary new];
    self.ingredients = [NSArray new];
    
    NSError *error;
    
    NSArray *supportedBarCodes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeAztecCode];
    
    // Get an instance of capture device and set video as the media type
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Set the captured device as the device input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!deviceInput) {
        NSLog(@"%@",error.localizedDescription);
        return;
    }
    
    captureSession = [[AVCaptureSession alloc]init];
    [captureSession addInput:deviceInput];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc]init];
    [captureSession addOutput:captureMetadataOutput];
    
    // Set the delegate and the queue for the call back
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [captureMetadataOutput setMetadataObjectTypes:supportedBarCodes];
    
    videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:captureSession];
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:videoPreviewLayer];
    
    [captureSession startRunning];
    [self.view bringSubviewToFront:self.messageLabel];
    
    qrCodeFrameView = [[UIView alloc]init];
    qrCodeFrameView.layer.borderColor = [[UIColor greenColor] CGColor];
    qrCodeFrameView.layer.borderWidth = 2.0;
    [self.view addSubview:qrCodeFrameView];
    [self.view bringSubviewToFront:qrCodeFrameView];
    [self.view bringSubviewToFront:self.tableView];
    
    [self.messageLabel setUserInteractionEnabled:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(reloadTable)];
    tap.numberOfTapsRequired = 2;
    [self.messageLabel addGestureRecognizer:tap];
    
    UITapGestureRecognizer *tableDismissTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissTable:)];
    tableDismissTap.numberOfTapsRequired = 1;
    [self.messageLabel addGestureRecognizer:tableDismissTap];
    
}

-(void)reloadTable{
    
        tableViewShowing = YES;
        self.tableView.frame = CGRectMake(-200.0, 0.0, 200.0, self.view.bounds.size.height - 50);
        self.tableView.hidden = NO;
        [UIView animateWithDuration:0.4 animations:^{
            self.tableView.frame = CGRectMake(0.0, 0.0, 200.0, self.view.bounds.size.height - 50);
        } completion:^(BOOL finished) {
            [self.tableView reloadData];
        }];

}

-(void)dismissTable:(UIGestureRecognizer *)sender{
    if (tableViewShowing) {
        [UIView animateWithDuration:0.4 animations:^{
            self.tableView.frame = CGRectMake(-200.0, 0.0, 200.0, self.view.bounds.size.height - 50);
        } completion:^(BOOL finished) {
            tableViewShowing = NO;
        }];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects == nil || metadataObjects.count == 0) {
        qrCodeFrameView.frame = CGRectZero;
        //self.messageLabel.text = @"No QR code is detected";
        return;
    }
    
    // Get the metadata object.
    AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
    
    //if ([metadataObj.type isEqualToString:AVMetadataObjectTypeQRCode]) {
        // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
        AVMetadataMachineReadableCodeObject *barCodeObject = (AVMetadataMachineReadableCodeObject *)[videoPreviewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadataObj];
        qrCodeFrameView.frame = barCodeObject.bounds;

    
    
    
        if (metadataObj.stringValue) {
            //self.messageLabel.text = [metadataObj stringValue];
            //NSLog(@"%@",[metadataObj stringValue]);
            
            NSString *urlString = [NSString stringWithFormat:@"http://world.openfoodfacts.org/api/v0/product/%@.json",[metadataObj stringValue]];
            NSLog(@"%@",urlString);
            //NSString *tempUrlString = @"http://world.openfoodfacts.org/api/v0/product/737628064502.json";
            NSString *temp2UrlString = @"http://world.openfoodfacts.org/api/v0/product/5900497610339.json";
            NSURL *url = [NSURL URLWithString:temp2UrlString];
            
            if ([temp2UrlString isEqualToString:previousUrl]) {
                return;
            }
            
            NSURLSessionTask *task = [[NSURLSession sharedSession]dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                self.information = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                self.ingredients = [[self.information objectForKey:@"product"] objectForKey:@"ingredients_tags"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadTable];
                    previousUrl = temp2UrlString;
                    [self printIngredients];
                    //self.tableView.hidden = NO;
                    //[self.tableView reloadData];
                });
                
            }];
            
            [task resume];
        }
//    }
    NSLog(@"%ld",self.information.count);
    
}

-(void)printIngredients{
    NSMutableString *ingredientList = [[NSMutableString alloc]init];
    for (NSString *ingredient in self.ingredients) {
        [ingredientList appendFormat:@" %@",ingredient];
        //NSLog(@"%@",ingredient);
    }
//    if ([ingredientList containsString:self.alergicIngredient]) {
        //NSLog(@"This product contains %@!",self.alergicIngredient);
//        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Warning" message:[NSString stringWithFormat:@"This product contains %@!",self.alergicIngredient] preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//        [controller addAction:action];
//        [self presentViewController:controller animated:YES completion:nil];
//    }
    self.tableView.hidden = NO;
    self.messageLabel.text = ingredientList;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.ingredients count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [self.ingredients objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor lightTextColor];
    
    return cell;
}

@end
