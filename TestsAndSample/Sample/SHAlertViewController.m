
#import "SHAlertViewController.h"
#import <SHPresenterBlocks.h>
@import QuartzCore;

@interface SHAlertViewControllerManager : NSObject
@property(nonatomic,strong) NSMutableDictionary     * blocksAlert;
@property(nonatomic,strong) NSMutableDictionary     * blocksContent;
@property(nonatomic,strong) NSMutableDictionary     * blocksButton;
@property(nonatomic,strong) NSMutableDictionary     * paddingType;
+(instancetype)sharedManager;

@end

@implementation SHAlertViewControllerManager

#pragma mark - Init & Dealloc
-(instancetype)init; {
  self = [super init];
  if (self) {
    self.blocksAlert       = @{}.mutableCopy;
    self.blocksContent     = @{}.mutableCopy;
    self.blocksButton      = @{}.mutableCopy;
    self.paddingType       = @{}.mutableCopy;
  }
  
  return self;
}


+(instancetype)sharedManager; {
  static id _sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[[self class] alloc] init];
  });
  
  return _sharedInstance;
  
}

@end

@interface SHAlertViewController ()
@property(nonatomic,strong)   NSMapTable * buttonCallbacks;
@property(nonatomic,readonly) NSArray    * buttons;
@property(nonatomic,strong) id observerToBackground;
@property(nonatomic,strong) UIView   * alertView;
@property(nonatomic,strong) UILabel  * lblTitle;
@property(nonatomic,strong) UILabel  * lblMessage;

@property(nonatomic,copy) SHAlertViewControllerCompletionBlock completion;
@property(nonatomic,weak) SHPresenterBlocks * presenter;

@property(nonatomic,readonly) NSString * alertStyle;

-(void)setupLayoutAlert;
-(void)setupLayoutTitle;
-(void)setupLayoutMessage;
-(void)setupLayoutButtons;
@end


@implementation SHAlertViewController

+(instancetype)alertWithTitle:(NSString *)theTitle
                      message:(NSString *)theMessage
                 buttonTitles:(NSArray *)theButtonTitles
                   completion:(SHAlertViewControllerCompletionBlock)theCompletion; {
  if([SHAlertViewControllerManager sharedManager].blocksButton[NSStringFromClass([self class])] == nil)
    [SHAlertViewController styleAlertButtonWithCompletionHandler:^UIControl *(NSInteger index, UIButton *button) {
      if(index == 0) button.tintColor = [UIColor redColor];
      else  button.tintColor = [UIColor blackColor];
      button.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
      button.titleLabel.font = [UIFont boldSystemFontOfSize:10.f];
      return button;
    }];
  
  if([SHAlertViewControllerManager sharedManager].blocksContent[NSStringFromClass([self class])] == nil)
    [SHAlertViewController styleAlertContentWithCompletionHandler:^id(NSInteger index, UILabel *lblContent) {
      if(index == 0) lblContent.tintColor = [UIColor blackColor];
      else  lblContent.tintColor = [UIColor redColor];
      return lblContent;
    }];
  
  if([SHAlertViewControllerManager sharedManager].blocksAlert[NSStringFromClass([self class])] == nil)
    [SHAlertViewController styleAlertViewWithCompletionHandler:^id(UIView *alertView) {
      alertView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
      alertView.layer.cornerRadius = 5.0;
      alertView.layer.shadowColor = [UIColor blackColor].CGColor;
      alertView.layer.shadowOpacity = 0.25;
      alertView.layer.shadowRadius = 1;
      alertView.layer.shadowOffset = CGSizeMake(0, 1);
      return alertView;
    }];

  SHAlertViewController * viewController = [[[self class] alloc] init];
  viewController.title = theTitle;
  viewController.message = theMessage;
  viewController.completion = theCompletion;
  [theButtonTitles enumerateObjectsUsingBlock:^(NSString * buttonTitle, __unused NSUInteger idx, __unused BOOL *stop) {
    [viewController addButtonWithTitle:buttonTitle completion:viewController.completion];
  }];

  return viewController;
}

-(instancetype)init; {
  self = [super init];
  if(self) {
    self.buttonCallbacks = [NSMapTable strongToWeakObjectsMapTable];
    self.presenter = [SHPresenterBlocks presenterWithName:@"com.SHAlertViewController.presenter"];
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

  }
  return self;
}

-(void)viewDidLoad; {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
  [self.view addSubview:self.alertView];
  [self.alertView addSubview:self.lblTitle];  
  [self.alertView addSubview:self.lblMessage];
//  self.alertView.alpha = 0;
}
-(void)viewWillAppear:(BOOL)animated; {
  [super viewWillAppear:animated];
  [self.view setNeedsUpdateConstraints];
}

-(void)viewDidAppear:(BOOL)animated; {
  [super viewDidAppear:animated];
  __weak typeof(self) weakSelf = self;
  self.observerToBackground = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    if([weakSelf.delegate respondsToSelector:@selector(alertViewCancel:)])
      [weakSelf.delegate alertViewCancel:(UIAlertView *)weakSelf];
    else
      [weakSelf dismissWithTappedButtonIndex:-1 animated:animated];
  }];
  
//  [UIView animateWithDuration:0.1 animations:^{self.alertView.alpha = 1.0;}];
//  
//  self.alertView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
//  
//  CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
//  bounceAnimation.values = [NSArray arrayWithObjects:
//                            [NSNumber numberWithFloat:0.5],
//                            [NSNumber numberWithFloat:1.1],
//                            [NSNumber numberWithFloat:0.8],
//                            [NSNumber numberWithFloat:1.0], nil];
//  bounceAnimation.duration = 0.3;
//  bounceAnimation.removedOnCompletion = NO;
//  [self.alertView.layer addAnimation:bounceAnimation forKey:@"bounce"];
//  
//  self.alertView.layer.transform = CATransform3DIdentity;
  
  //  [UIView animateWithDuration:0.1 animations:^{
  //    self.alertView.alpha = 1;
  //  }];
  //
  //  self.alertView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
  //
  //  [UIView animateKeyframesWithDuration:0.3 delay:0 options:kNilOptions animations:^{
  //    [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.25 animations:^{
  //      self.alertView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
  //    }];
  //    [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
  //      self.alertView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.0);
  //    }];
  //    [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.25 animations:^{
  //      self.alertView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1.0);
  //    }];
  //    [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
  //      self.alertView.layer.transform = CATransform3DMakeScale(1.f, 1.f, 1.0);
  //    }];
  //
  //  } completion:^(BOOL finished) {
  //    self.alertView.layer.transform = CATransform3DIdentity;
  //  }];

}

-(void)viewWillDisappear:(BOOL)animated; {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self.observerToBackground];
}



#pragma mark - Layout

-(void)addButtonWithTitle:(NSString *)theButtonTitle
               completion:(SHAlertViewControllerCompletionBlock)theCompletion; {
  NSParameterAssert(theButtonTitle);
  NSParameterAssert(theCompletion);
  
  UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:theButtonTitle forState:UIControlStateNormal];
  [button addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
  SHAlertViewControllerCreateButtonBlock contentBlock =[SHAlertViewControllerManager sharedManager].blocksButton[self.alertStyle];
  if(contentBlock) button = (UIButton *)contentBlock(self.numberOfButtons, button);
  NSParameterAssert(button);
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [self.alertView addSubview:button];
  [self.view setNeedsUpdateConstraints];
  [self.buttonCallbacks setObject:theCompletion forKey:button];
}


-(void)tappedButton:(UIButton *)theButton; {
  NSInteger index = [self.buttons indexOfObject:theButton];
  SHAlertViewControllerCompletionBlock  block = [self.buttonCallbacks objectForKey:theButton];
  if(block) block(index);
  [self dismissWithTappedButtonIndex:index animated:YES];
  
}
#pragma mark - Properties

-(void)setTitle:(NSString *)title; {
  [super setTitle:title];
  self.lblTitle.text = title;
}

-(void)setMessage:(NSString *)message; {
  _message = message;
  self.lblMessage.text = message;
}

-(void)setAttributedMessage:(NSAttributedString *)attributedMessage; {
  _attributedMessage = attributedMessage;
  self.lblMessage.attributedText = attributedMessage;
}

-(void)setAttributedTitle:(NSAttributedString *)attributedTitle; {
  _attributedTitle = attributedTitle;
  self.lblTitle.attributedText = attributedTitle;
}


#pragma mark - Actions

-(void)dismissWithTappedButtonIndex:(NSInteger)theButtonIndex animated:(BOOL)theAnimatedFlag; {
  [self.delegate alertView:(UIAlertView *)self clickedButtonAtIndex:theButtonIndex];
  [self.delegate alertView:(UIAlertView *)self willDismissWithButtonIndex:theButtonIndex];

  __weak typeof(self) weakSelf = self;
  [self.presentingViewController dismissViewControllerAnimated:theAnimatedFlag completion:^{
    [weakSelf.delegate alertView:(UIAlertView *)weakSelf didDismissWithButtonIndex:theButtonIndex];
  }];
}

-(void)show; {
  [self.delegate willPresentAlertView:(UIAlertView *)self];
  [self.presenter enqueueViewController:self windowLevel:UIWindowLevelAlert animated:NO completion:^(UIViewController *controller) {
    [self.delegate didPresentAlertView:(UIAlertView *)self];
  }];
}




#pragma mark - Lazy Loading

-(UILabel *)lblTitle; {
  if (_lblTitle == nil) {
    _lblTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    _lblTitle.textAlignment = NSTextAlignmentCenter;
    _lblTitle.numberOfLines = 0;
    SHAlertViewControllerCreateContentHolderBlock contentBlock =[SHAlertViewControllerManager sharedManager].blocksContent[self.alertStyle];
    _lblTitle = (id)contentBlock(0,_lblTitle);
    NSParameterAssert(_lblTitle);
    _lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _lblTitle;
}

-(UILabel *)lblMessage; {
  if (_lblMessage == nil) {
    _lblMessage = [[UILabel alloc] initWithFrame:CGRectZero];
    _lblMessage.textAlignment = NSTextAlignmentCenter;
    _lblMessage.numberOfLines = 0;
    SHAlertViewControllerCreateContentHolderBlock contentBlock =[SHAlertViewControllerManager sharedManager].blocksContent[self.alertStyle];
    _lblMessage = (id)contentBlock(1,_lblMessage);
    NSParameterAssert(_lblMessage);
    _lblMessage.translatesAutoresizingMaskIntoConstraints = NO;

  }
  return _lblMessage;
}


-(UIView *)alertView; {
  if (_alertView == nil) {
    _alertView = [[UIView alloc] initWithFrame:CGRectZero];
    SHAlertViewControllerCreateAlertBlock contentBlock =[SHAlertViewControllerManager sharedManager].blocksAlert[self.alertStyle];
    if(contentBlock) _alertView = contentBlock(_alertView);
    _alertView.translatesAutoresizingMaskIntoConstraints = NO;
    NSParameterAssert(_alertView);
  }
  return _alertView;
}

-(NSString *)buttonTitleAtIndex:(NSInteger)theButtonIndex; {
  UIButton * button = self.buttons[theButtonIndex];
  return [button titleForState:UIControlStateNormal];
}

-(NSInteger)addButtonWithTitle:(NSString *)title; {
  [self addButtonWithTitle:title completion:self.completion];
  
  return self.numberOfButtons-1;
}

-(NSArray *)buttons; {
  NSMutableOrderedSet * setOfSubviews = [NSMutableOrderedSet orderedSetWithArray:self.alertView.subviews];
  [setOfSubviews intersectSet:[NSSet setWithArray:self.buttonCallbacks.keyEnumerator.allObjects]];
  return setOfSubviews.array;
}

-(NSInteger)numberOfButtons; {
  return self.buttonCallbacks.count;
}
//@property(nonatomic,readonly) NSInteger firstOtherButtonIndex;
-(BOOL)isVisible; {
  return self.presenter.topViewController == self;
}

-(void)updateViewConstraints; {
  [super updateViewConstraints];
  [self.view removeConstraints:self.view.constraints];
  [self.alertView removeConstraints:self.alertView.constraints];
  [self setupLayoutAlert];
  [self setupLayoutTitle];
  [self setupLayoutMessage];
  [self setupLayoutButtons];

  
}


-(void)setupLayoutAlert; {
  [self.view addConstraint:  [NSLayoutConstraint constraintWithItem:self.alertView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.f constant:0.f]];
  
  
  NSArray * constraintForAlertView = [NSLayoutConstraint
                                      constraintsWithVisualFormat:@"V:|-(>=0)-[_alertView]"
                                      options: kNilOptions
                                      metrics:nil
                                      views:NSDictionaryOfVariableBindings(_alertView)];
  
  constraintForAlertView = [constraintForAlertView arrayByAddingObjectsFromArray:
                            [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_alertView]-|"
                                                                    options: kNilOptions
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(_alertView)]
                            ];
  
  [self.view addConstraints:constraintForAlertView];

}

-(void)setupLayoutTitle; {
  NSArray * constraintForTitle = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_lblTitle]-|"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_lblTitle)];
  

  constraintForTitle = [constraintForTitle arrayByAddingObjectsFromArray:
                        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_lblTitle]"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_lblTitle)]
                        ];
  [self.alertView addConstraints:constraintForTitle];
}

-(void)setupLayoutMessage; {
  NSArray * constraintForMessage = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_lblMessage]-|"
                                                                           options:kNilOptions
                                                                           metrics:nil
                                                                             views:NSDictionaryOfVariableBindings(_lblMessage)];
  
  
  
  
  if(self.buttons.firstObject)
    constraintForMessage = [constraintForMessage arrayByAddingObjectsFromArray:
                            [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_lblTitle][_lblMessage]"
                                                                    options:kNilOptions
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(_lblMessage, _lblTitle)]
                            ];
  else
    constraintForMessage = [constraintForMessage arrayByAddingObjectsFromArray:
                            [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_lblTitle]-[_lblMessage]-|"
                                                                    options:kNilOptions
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(_lblMessage, _lblTitle)]
                            ];
  
  
  
  [self.alertView addConstraints:constraintForMessage];
}

-(void)setupLayoutButtons; {
  [self.buttons enumerateObjectsUsingBlock:^(UIButton * button, NSUInteger idx, __unused BOOL *stop) {
    
    NSArray * constraintForButton = @[];
    
    constraintForButton =  [constraintForButton arrayByAddingObjectsFromArray:
                            [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[button]-|"
                                                                    options:kNilOptions
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(button)]];
    
    if(self.buttons.firstObject == button && self.buttons.lastObject == button)
      constraintForButton = [constraintForButton arrayByAddingObjectsFromArray:
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_lblMessage]-[button]-|"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_lblMessage, button)]
                             ];
    else if(self.buttons.firstObject == button)
      constraintForButton = [constraintForButton arrayByAddingObjectsFromArray:
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_lblMessage]-[button]"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_lblMessage, button)]
                             ];
    
    else if(self.buttons.lastObject == button) {
      UIButton * previousButton = self.buttons[idx-1];
      constraintForButton = [constraintForButton arrayByAddingObjectsFromArray:
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[previousButton]-[button]-|"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(previousButton,button)]
                             ];
    }
    else {
      UIButton * previousButton = self.buttons[idx-1];
      constraintForButton = [constraintForButton arrayByAddingObjectsFromArray:
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[previousButton]-[button]"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(previousButton,button)]
                             ];
    }
    
    
    
    [self.alertView addConstraints:constraintForButton];
    
  }];
}

+(void)styleAlertViewWithCompletionHandler:(SHAlertViewControllerCreateAlertBlock)completionHandler; {
  [SHAlertViewControllerManager sharedManager].blocksAlert[NSStringFromClass([self class])] = completionHandler;
}

+(void)styleAlertContentWithCompletionHandler:(SHAlertViewControllerCreateContentHolderBlock)completionHandler; {
  [SHAlertViewControllerManager sharedManager].blocksContent[NSStringFromClass([self class])] = completionHandler;
}

+(void)styleAlertButtonWithCompletionHandler:(SHAlertViewControllerCreateButtonBlock)completionHandler; {
  [SHAlertViewControllerManager sharedManager].blocksButton[NSStringFromClass([self class])] = completionHandler;
}

-(NSString *)alertStyle; {
  return NSStringFromClass([self class]);
}

+(void)setLayoutWithPaddingType:(SHAlertViewControllerPadding)thePaddingType padding:(CGFloat)thePadding; {
  NSMutableDictionary * paddings = [SHAlertViewControllerManager sharedManager].paddingType[NSStringFromClass([self class])];
  if(paddings == nil) paddings = @{}.mutableCopy;
  paddings[@(thePaddingType)] = @(thePadding);
  [[SHAlertViewControllerManager sharedManager].paddingType setObject:paddings forKey:NSStringFromClass([self class])];
}

+(NSNumber *)paddingForLayoutPaddingType:(SHAlertViewControllerPadding)thePaddingType; {
  NSMutableDictionary * paddings = [SHAlertViewControllerManager sharedManager].paddingType[NSStringFromClass([self class])];
  return paddings[@(thePaddingType)];
}
@end
