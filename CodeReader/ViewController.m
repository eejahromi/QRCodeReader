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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
    
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
            
            NSURL *url = [NSURL URLWithString:urlString];
            
            NSURLSessionTask *task = [[NSURLSession sharedSession]dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                self.information = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                self.ingredients = [[self.information objectForKey:@"product"] objectForKey:@"ingredients_tags"];
                dispatch_async(dispatch_get_main_queue(), ^{
                        //[self printIngredients];
                    self.tableView.hidden = NO;
                    [self.tableView reloadData];
                });
                
            }];
            
            [task resume];
        }
//    }
    
    
    
}

-(void)printIngredients{
    NSMutableString *ingredientList = [[NSMutableString alloc]init];
    for (NSString *ingredient in self.ingredients) {
        [ingredientList appendFormat:@" %@",ingredient];
    }
//    if ([ingredientList containsString:self.alergicIngredient]) {
        //NSLog(@"This product contains %@!",self.alergicIngredient);
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Warning" message:[NSString stringWithFormat:@"This product contains %@!",self.alergicIngredient] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [controller addAction:action];
        [self presentViewController:controller animated:YES completion:nil];
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
