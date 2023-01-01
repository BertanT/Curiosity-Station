//
//  ParticleSetupViewController.m
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 12/13/14.
//  Copyright (c) 2014-2015 Particle. All rights reserved.
//

#import "ParticleSetupUIViewController.h"
#import "ParticleSetupCustomization.h"

@interface ParticleSetupUIViewController ()
@property(nonatomic, assign) CGFloat kbSizeHeight;
@property(weak, nonatomic) IBOutlet UIImageView *brandImageView;
@property(nonatomic, strong) UITapGestureRecognizer *tap;
@end

@implementation ParticleSetupUIViewController

#pragma mark view controller life cycle

@synthesize backgroundView = _backgroundView;

- (void)viewDidLoad {
    [super viewDidLoad];

    //Force light mode on iOS 13
    if (@available(iOS 13.0, *)) {
        if ([self respondsToSelector:NSSelectorFromString(@"overrideUserInterfaceStyle")]) {
            [self setValue:@(UIUserInterfaceStyleLight) forKey:@"overrideUserInterfaceStyle"];
        }
    }

    if ([ParticleSetupCustomization sharedInstance].pageBackgroundImage) {
        UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[ParticleSetupCustomization sharedInstance].pageBackgroundImage];
        backgroundImage.translatesAutoresizingMaskIntoConstraints = NO;
        backgroundImage.contentMode = UIViewContentModeScaleToFill;

        [self.view addSubview:backgroundImage];
        [self.view sendSubviewToBack:backgroundImage];

        [backgroundImage.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [backgroundImage.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
        [backgroundImage.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [backgroundImage.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

        _backgroundView = backgroundImage;
    }


    if ([ParticleSetupCustomization sharedInstance].pageBackgroundColor) //TODO: check this
    {
        UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        view.backgroundColor = [ParticleSetupCustomization sharedInstance].pageBackgroundColor;
        view.translatesAutoresizingMaskIntoConstraints = NO;

        [self.view addSubview:view];
        [self.view sendSubviewToBack:view];

        [view.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
        [view.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

        _backgroundView = view;
    }

    [self replaceSetupStrings:self.view];
}


- (void)replaceSetupStrings:(UIView *)target {
    NSArray<UIView *> *subviews = target.subviews;

    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *) subview;
            label.text = [label.text particleLocalized];
        } else if ([subview isKindOfClass:[UIButton class]]) {
            [UIView performWithoutAnimation:^{
                UIButton *button = (UIButton *) subview;
                [button setTitle:[button.currentTitle particleLocalized] forState:UIControlStateNormal];
                [button layoutIfNeeded];
            }];
        } else if ([subview isKindOfClass:[UITextView class]]) {
            UITextView *textview = (UITextView *) subview;
            textview.text = [textview.text particleLocalized];
        } else if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *textfield = (UITextField *) subview;
            textfield.text = [textfield.text particleLocalized];
            textfield.placeholder = [textfield.placeholder particleLocalized];
        } else {
            [self replaceSetupStrings:subview];
        }
    }
}


- (void)trimTextFieldValue:(UITextField *)textfield {
    textfield.text = [textfield.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)disableKeyboardMovesViewUp {
    // TODO: something less hacky
    [self viewWillDisappear:NO];

}

#pragma mark public methods


- (BOOL)isValidEmail:(NSString *)checkString // TODO: move to NSString category under helpers (as well as encode/decode hex)
{
    NSString *emailRegex =
            @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
            @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
            @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
            @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
            @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
            @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
            @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}


#pragma mark - Notifications / Keyboard move handling

- (void)keyboardWillShow:(NSNotification *)notification {
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.tap.cancelsTouchesInView = YES; // to enable touches to go through tableviews, etc
    [self.view addGestureRecognizer:self.tap];

    self.kbSizeHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.kbSizeHeight -= [self keyboardHeightAdjust];

    if (self.view.frame.origin.y >= 0) {
        [self setViewMovedUp:YES];
    } else if (self.view.frame.origin.y < 0) {
        [self setViewMovedUp:NO];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self.view removeGestureRecognizer:self.tap];

    if (self.view.frame.origin.y >= 0) {
        [self setViewMovedUp:YES];
    } else if (self.view.frame.origin.y < 0) {
        [self setViewMovedUp:NO];
    }
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (CGFloat)keyboardHeightAdjust {
    if (isiPhone4) return 64.0;
    else if (isiPhone5) return 48.0;
    else return 32.0;
}


//method to move the view up/down whenever the keyboard is shown/dismissed
- (void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];

    CGRect rect = self.view.frame;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= self.kbSizeHeight;
        rect.size.height += self.kbSizeHeight;
    } else {
        // revert back to the normal state.
        rect.origin.y += self.kbSizeHeight;
        rect.size.height -= self.kbSizeHeight;
    }
    self.view.frame = rect;
    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

@end
