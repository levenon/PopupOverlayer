//
//  POPopupOverlayer.h
//  pyyx
//
//  Created by xulinfeng on 16/9/21.
//  Copyright © 2016年 Chunlin Ma. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, POPopupOverlayerAnimationDirection) {
    POPopupOverlayerAnimationDirectionNone   = 0,
    POPopupOverlayerAnimationDirectionTop     = 1 << 0,
    POPopupOverlayerAnimationDirectionBottom   = 1 << 1,
    POPopupOverlayerAnimationDirectionLeft   = 1 << 2,
    POPopupOverlayerAnimationDirectionRight  = 1 << 3,
    POPopupOverlayerAnimationDirectionRandom = 1 << 4,
};

@class POPopupOverlayer;
@protocol POPopupOverlayerDelegate <NSObject>
@optional
- (CGSize)popupOverlayer:(POPopupOverlayer *)popupOverlayer sizeForItemAtIndex:(NSUInteger)nIndex;

// Display customization
- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer willDisplayItemView:(UIView *)itemView atIndex:(NSUInteger)nIndex;
- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer didEndDisplayingItemView:(UIView *)itemView atIndex:(NSUInteger)nIndex;

- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer willMoveItemAtIndex:(NSUInteger)nIndex;

- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer movingItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;
// If this method hasn't been implemented, it caculate with content width. eg: translation.x / content-width
- (CGFloat)popupOverlayer:(POPopupOverlayer *)popupOverlayer progressMovingItemViewWithTranslation:(CGPoint)translation sizeForItemAtIndex:(NSUInteger)nIndex;

- (CATransform3D)popupOverlayer:(POPopupOverlayer *)popupOverlayer itemViewTransformForTranslation:(CGPoint)translation defaultTransform:(CATransform3D)transform;
- (CATransform3D)popupOverlayer:(POPopupOverlayer *)popupOverlayer itemViewTransformOnDirection:(POPopupOverlayerAnimationDirection)direction defaultTransform:(CATransform3D)transform;

- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer didMoveItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex;

- (BOOL)popupOverlayer:(POPopupOverlayer *)popupOverlayer shouldPopupOverItemView:(UIView *)itemView direction:(POPopupOverlayerAnimationDirection)direction atIndex:(NSUInteger)nIndex;
- (void)popupOverlayer:(POPopupOverlayer *)popupOverlayer didPopupOverItemViewOnDirection:(POPopupOverlayerAnimationDirection)direction atIndex:(NSUInteger)nIndex;

@end

@protocol POPopupOverlayerDataSource <NSObject>

@optional
- (BOOL)popupOverlayer:(POPopupOverlayer *)popupOverlayer canMoveItemViewAtIndex:(NSUInteger)nIndex;

@required
- (UIView *)popupOverlayer:(POPopupOverlayer *)popupOverlayer viewForItemAtIndex:(NSUInteger)nIndex reusingView:(UIView *)view;

- (NSInteger)numberOfItemsInPopupOverlayerView:(POPopupOverlayer *)popupOverlayer;

- (NSInteger)numberOfVisibleItemsInPopupOverlayerView:(POPopupOverlayer *)popupOverlayer;

@end

@interface POPopupOverlayer : UIView

@property (nonatomic, assign) id<POPopupOverlayerDelegate> delegate;
@property (nonatomic, assign) id<POPopupOverlayerDataSource> dataSource;
@property (nonatomic, assign) POPopupOverlayerAnimationDirection allowDirections;
@property (nonatomic, assign) POPopupOverlayerAnimationDirection allowBackToFront;
@property (nonatomic, strong, readonly) NSArray *visibleItemViews;
@property (nonatomic, assign) CGSize maxTranslation;        // Default is half of size;
@property (nonatomic, assign) CGFloat itemViewRotateAngle;         // Default is 10/180.f * M_PI
@property (nonatomic, assign, readonly) NSUInteger numberOfVisibleItemViews; // Default is 3.
@property (nonatomic, assign, readonly) NSUInteger numberOfItemViews;
@property (nonatomic, assign, readonly) NSUInteger currentItemIndex;

- (POPopupOverlayerAnimationDirection)directionAtTranslation:(CGPoint)translation;

- (BOOL)popOverTopItemViewOnDirection:(POPopupOverlayerAnimationDirection)direction animated:(BOOL)animated;

- (void)insertItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated;
- (void)removeItemAtIndex:(NSUInteger)nIndex onDirection:(POPopupOverlayerAnimationDirection)direction animated:(BOOL)animated;
- (void)reloadItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated;
- (void)reloadData;

@end
