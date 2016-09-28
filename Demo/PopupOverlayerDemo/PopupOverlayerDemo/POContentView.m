//
//  POContentView.m
//  pyyx
//
//  Created by xulinfeng on 16/9/21.
//  Copyright © 2016年 Chunlin Ma. All rights reserved.
//

#import "POContentView.h"
#import "POPopupOverlayer.h"

@interface POContentView ()<POPopupOverlayerDelegate, POPopupOverlayerDataSource>

@property (nonatomic, strong) POPopupOverlayer *popupOverlayer;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *likeButton;

@property (nonatomic, strong) UIButton *insertButton;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation POContentView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self _createSubviews];
        [self _configurateSubviewsDefault];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.closeButton.frame = CGRectMake(24, 174, 48, 48);
    self.likeButton.frame = CGRectMake(CGRectGetWidth([self bounds]) - 24 - 48, 174, 48, 48);
    
    self.insertButton.frame = CGRectMake(24, 400, 98, 48);
    self.deleteButton.frame = CGRectMake(CGRectGetWidth([self bounds]) - 24 - 98, 400, 98, 48);
    
    self.popupOverlayer.frame = CGRectMake(CGRectGetWidth([self bounds]) / 2. - 167/2., 124, 167, 167);
}

#pragma mark - private

- (void)_createSubviews{
    
    self.popupOverlayer = [POPopupOverlayer new];
    self.closeButton = [UIButton new];
    self.likeButton = [UIButton new];
    self.insertButton = [UIButton new];
    self.deleteButton = [UIButton new];
    
    [self addSubview:[self closeButton]];
    [self addSubview:[self likeButton]];
    [self addSubview:[self insertButton]];
    [self addSubview:[self deleteButton]];
    [self addSubview:[self popupOverlayer]];
}

- (void)_configurateSubviewsDefault{
    
    self.dataSource = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", @"", @"", nil];
    
    self.popupOverlayer.delegate = self;
    self.popupOverlayer.dataSource = self;
    self.popupOverlayer.maxTranslation = CGSizeMake(160, 160);
    self.popupOverlayer.itemViewRotateAngle = 5/180.f * M_PI;
    
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.closeButton.layer.cornerRadius = 48/2.;
    self.closeButton.layer.borderWidth = 1.f;
    self.closeButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [[self closeButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self closeButton] setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [[self closeButton] setTitle:@"L" forState:UIControlStateNormal];
    [[self closeButton] addTarget:self action:@selector(didClickClose:) forControlEvents:UIControlEventTouchUpInside];
    
    self.insertButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.insertButton.layer.cornerRadius = 48/2.;
    self.insertButton.layer.borderWidth = 1.f;
    self.insertButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    [[self insertButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self insertButton] setTitle:@"insert" forState:UIControlStateNormal];
    [[self insertButton] addTarget:self action:@selector(didClickInsert:) forControlEvents:UIControlEventTouchUpInside];
    
    self.likeButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.likeButton.layer.cornerRadius = 48/2.;
    self.likeButton.layer.borderWidth = 1.f;
    self.likeButton.layer.borderColor = [[UIColor redColor] CGColor];
    [[self likeButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [[self likeButton] setTitleColor:[UIColor greenColor] forState:UIControlStateHighlighted];
    [[self likeButton] setTitle:@"R" forState:UIControlStateNormal];
    [[self likeButton] addTarget:self action:@selector(didClickLike:) forControlEvents:UIControlEventTouchUpInside];
    
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:24];
    self.deleteButton.layer.cornerRadius = 48/2.;
    self.deleteButton.layer.borderWidth = 1.f;
    self.deleteButton.layer.borderColor = [[UIColor redColor] CGColor];
    [[self deleteButton] setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [[self deleteButton] setTitle:@"delete" forState:UIControlStateNormal];
    [[self deleteButton] addTarget:self action:@selector(didClickDelete:) forControlEvents:UIControlEventTouchUpInside];
    
    [[self popupOverlayer] reloadData];
}

#pragma mark - POPopupOverlayerDelegate, POPopupOverlayerDataSource

- (NSInteger)numberOfItemsInPopupOverlayerView:(POPopupOverlayer *)popupOverlayer;{
    return [[self dataSource] count];
}

- (NSInteger)numberOfVisibleItemsInPopupOverlayerView:(POPopupOverlayer *)popupOverlayer;{
    return 3;
}

- (CGSize)popupOverlayer:(POPopupOverlayer *)popupOverlayer sizeForItemAtIndex:(NSUInteger)nIndex;{
    return CGSizeMake(160, 160);
}

- (UIView *)popupOverlayer:(POPopupOverlayer *)popupOverlayer viewForItemAtIndex:(NSUInteger)nIndex reusingView:(UIView *)view;{
    if (!view) {
        view = [UIView new];
    }
    view.layer.cornerRadius = 4;
    view.layer.borderWidth = 2;
    view.layer.masksToBounds = YES;
    view.layer.borderColor = [[UIColor whiteColor] CGColor];
    view.backgroundColor = [UIColor colorWithRed:(arc4random()%255)/255.f green:(arc4random()%255)/255.f blue:(arc4random()%255)/255.f alpha:1];
    
    return view;
}

- (BOOL)popupOverlayer:(POPopupOverlayer *)popupOverlayer shouldPopupOverItemView:(UIView *)itemView direction:(POPopupOverlayerAnimationDirection)direction atIndex:(NSUInteger)nIndex;{
    return YES;
}

- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer movingItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;{
    POPopupOverlayerAnimationDirection direction = [popupOverlayer directionAtTranslation:translation];
    self.closeButton.highlighted = direction & POPopupOverlayerAnimationDirectionLeft;
    self.likeButton.highlighted = direction & POPopupOverlayerAnimationDirectionRight;
}

- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer didMoveItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;{
    self.closeButton.highlighted = NO;
    self.likeButton.highlighted = NO;
}

- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer didPopupOverItemViewOnDirection:(POPopupOverlayerAnimationDirection)direction atIndex:(NSUInteger)nIndex;{
}

#pragma mark - actions

- (IBAction)didClickInsert:(id)sender{
    [[self dataSource] insertObject:@"" atIndex:1];
    [[self popupOverlayer] insertItemAtIndex:1 animated:YES];
}

- (IBAction)didClickDelete:(id)sender{
    
    [[self dataSource] removeObjectAtIndex:1];
    [[self popupOverlayer] removeItemAtIndex:1 onDirection:POPopupOverlayerAnimationDirectionBottom animated:YES];
}

- (IBAction)didClickClose:(id)sender{
    
    [[self popupOverlayer] popOverTopItemViewOnDirection:POPopupOverlayerAnimationDirectionLeft animated:YES];
}

- (IBAction)didClickLike:(id)sender{
    
    [[self popupOverlayer] popOverTopItemViewOnDirection:POPopupOverlayerAnimationDirectionRight animated:YES];
}

@end
