//
//  ParticleSetupPasswordEntryViewController.m
//  teacup-ios-app
//
//  Created by Ido on 1/20/15.
//  Copyright (c) 2015 particle. All rights reserved.
//

#import "ParticleSetupPasswordEntryViewController.h"
#import "ParticleSetupUILabel.h"
#import "ParticleSetupCustomization.h"
#import "ParticleConnectingProgressViewController.h"
#import "ParticleSetupCommManager.h"
#import "ParticleSetupCustomization.h"
#import "ParticleSetupMainController.h"

#ifdef ANALYTICS
#import <SEGAnalytics.h>
#endif

@interface ParticleSetupPasswordEntryViewController () <UITextFieldDelegate>
@property(weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property(weak, nonatomic) IBOutlet ParticleSetupUILabel *networkNameLabel;
@property(weak, nonatomic) IBOutlet ParticleSetupUILabel *securityTypeLabel;
@property(weak, nonatomic) IBOutlet UISwitch *showPasswordSwitch;
@property(weak, nonatomic) IBOutlet UIImageView *brandImageView;
@property(weak, nonatomic) IBOutlet UIImageView *brandBackgroundImageView;
@property(weak, nonatomic) IBOutlet UIImageView *wifiSymbolImageView;
@property(weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation ParticleSetupPasswordEntryViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return ([ParticleSetupCustomization sharedInstance].lightStatusAndNavBar) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // move to super viewdidload?
    self.brandImageView.image = [ParticleSetupCustomization sharedInstance].brandImage;
    self.brandImageView.backgroundColor = [UIColor clearColor];
    self.brandBackgroundImageView.backgroundColor = [ParticleSetupCustomization sharedInstance].brandImageBackgroundColor;
    self.brandBackgroundImageView.image = [ParticleSetupCustomization sharedInstance].brandImageBackgroundImage;


    UIColor *navBarButtonsColor = ([ParticleSetupCustomization sharedInstance].lightStatusAndNavBar) ? [UIColor whiteColor] : [UIColor blackColor];
    [self.backButton setTitleColor:navBarButtonsColor forState:UIControlStateNormal];


    // force load images from resource bundle
    self.wifiSymbolImageView.image = [ParticleSetupMainController loadImageFromResourceBundle:@"wifi3"];

    // Trick to add an inset from the left of the text fields
    CGRect viewRect = CGRectMake(0, 0, 10, 32);
    UIView *emptyView = [[UIView alloc] initWithFrame:viewRect];

    self.passwordTextField.leftView = emptyView;
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.delegate = self;
    self.passwordTextField.returnKeyType = UIReturnKeyJoin;

    self.passwordTextField.font = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].normalTextFontName size:16.0];

    self.networkNameLabel.text = self.networkName;
    self.securityTypeLabel.text = [self convertSecurityTypeToString:self.security];
    self.showPasswordSwitch.onTintColor = [ParticleSetupCustomization sharedInstance].elementBackgroundColor;

    self.wifiSymbolImageView.image = [self.wifiSymbolImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.wifiSymbolImageView.tintColor = [ParticleSetupCustomization sharedInstance].normalTextColor;// elementBackgroundColor;;

    self.backButton.imageView.image = [self.backButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.backButton.tintColor = navBarButtonsColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showPasswordSwitchTapped:(id)sender {
    self.passwordTextField.secureTextEntry = self.showPasswordSwitch.isOn;

    // Hack to update cursor position to match new length of dots/chars
    NSString *tmp = self.passwordTextField.text;
    self.passwordTextField.text = @" ";
    self.passwordTextField.text = tmp;

}


- (void)viewWillAppear:(BOOL)animated {
#ifdef ANALYTICS
    [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_PasswordEntryScreen"];
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.passwordTextField becomeFirstResponder];
}


- (IBAction)connectButtonTapped:(id)sender {
    int minWifiPassChars = 8;
    if ([self.securityTypeLabel.text rangeOfString:@"WEP"].length > 0) //iOS7 way to do it (still need to do something nicer here)
        minWifiPassChars = 5;

    if (self.passwordTextField.text.length < minWifiPassChars) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[ParticleSetupStrings_NetworkPassword_Error_InvalidPassword_Title variablesReplaced]
                                                        message:[[ParticleSetupStrings_NetworkPassword_Error_InvalidPassword_Message variablesReplaced] stringByReplacingOccurrencesOfString:@"{{length}}" withString:[@(minWifiPassChars) stringValue]]
                                                       delegate:nil cancelButtonTitle:[ParticleSetupStrings_Action_Ok variablesReplaced] otherButtonTitles:nil];
        [alert show];
    } else {
        [self.view endEditing:YES];
        [self performSegueWithIdentifier:@"connect" sender:self];
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"connect"]) {
        // Get reference to the destination view controller
        ParticleConnectingProgressViewController *vc = [segue destinationViewController];
        vc.networkName = self.networkName;
        vc.channel = self.channel;
        vc.security = self.security;
        vc.password = self.passwordTextField.text;
        vc.deviceID = self.deviceID; // propagate device ID
        vc.needToClaimDevice = self.needToClaimDevice; // propagate claiming
    }

}

- (NSString *)convertSecurityTypeToString:(NSNumber *)securityType {
    switch ([securityType intValue]) {
        case ParticleSetupWifiSecurityTypeOpen:
            return @"Open";
            break;
        case ParticleSetupWifiSecurityTypeWEP_PSK:
            return @"WEP-PSK";
            break;
        case ParticleSetupWifiSecurityTypeWEP_SHARED:
            return @"WEP-Shared";
            break;
        case ParticleSetupWifiSecurityTypeWPA_TKIP_PSK:
            return @"WPA-TKIP";
            break;
        case ParticleSetupWifiSecurityTypeWPA_AES_PSK:
            return @"WPA-AES";
            break;
        case ParticleSetupWifiSecurityTypeWPA2_AES_PSK:
            return @"WPA2-AES";
            break;
        case ParticleSetupWifiSecurityTypeWPA2_TKIP_PSK:
            return @"WPA2-TKIP";
            break;
        case ParticleSetupWifiSecurityTypeWPA2_MIXED_PSK:
            return @"WPA2-Mixed";
            break;
        default:
            return @"Unknown";
            break;
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.passwordTextField) {
        [self connectButtonTapped:self];
    }

    return YES;
}


- (IBAction)changeNetworkButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
