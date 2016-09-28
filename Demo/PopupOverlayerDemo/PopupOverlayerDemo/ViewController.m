//
//  ViewController.m
//  PopupOverlayerDemo
//
//  Created by xulinfeng on 16/9/28.
//  Copyright © 2016年 markejave. All rights reserved.
//

#import "ViewController.h"
#import "POContentView.h"

@interface ViewController ()

@property (nonatomic, strong) POContentView *contentView;

@end

@implementation ViewController

- (void)loadView{
    [super loadView];
    
    [[self view] addSubview:[self contentView]];
}

- (POContentView *)contentView{
    if (!_contentView) {
        _contentView = [[POContentView alloc] initWithFrame:[[self view] bounds]];
        _contentView.backgroundColor = [UIColor lightGrayColor];
    }
    return _contentView;
}

@end
