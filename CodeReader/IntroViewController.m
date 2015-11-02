//
//  IntroViewController.m
//  CodeReader
//
//  Created by Ehsan on 11/1/15.
//  Copyright © 2015 Ehsan Jahromi. All rights reserved.
//

#import "IntroViewController.h"
#import "ViewController.h"

@interface IntroViewController ()
@property (weak, nonatomic) IBOutlet UITextField *ingredientsTextField;
@property (strong,nonatomic) NSString *ingredient;
@end

@implementation IntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonPressed:(UIButton *)sender {
    [self.ingredientsTextField resignFirstResponder];
    self.ingredient = self.ingredientsTextField.text;
    [self performSegueWithIdentifier:@"ShowScanner" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ViewController *scannerVC = segue.destinationViewController;
    scannerVC.alergicIngredient = self.ingredient;
    
    
}


@end
