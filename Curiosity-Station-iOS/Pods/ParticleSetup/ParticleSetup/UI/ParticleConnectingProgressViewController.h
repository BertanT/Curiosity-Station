//
//  ParticleConnectiProgressViewController.h
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 11/25/14.
//  Copyright (c) 2014-2015 Particle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParticleSetupUIViewController.h"

@interface ParticleConnectingProgressViewController : ParticleSetupUIViewController
@property(nonatomic, strong) NSString *networkName;
@property(nonatomic, strong) NSString *deviceID;
@property(nonatomic, strong) NSString *password;
@property(nonatomic, strong) NSNumber *channel;
@property(nonatomic, strong) NSNumber *security;
@property(nonatomic) BOOL needToClaimDevice;
@end
