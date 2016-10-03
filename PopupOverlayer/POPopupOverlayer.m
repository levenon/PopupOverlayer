//
//  POPopupOverlayer.m
//  pyyx
//
//  Created by xulinfeng on 16/9/21.
//  Copyright © 2016年 Chunlin Ma. All rights reserved.
//

#import "POPopupOverlayer.h"

CGFloat POPopupOverlayerAnimationDuration = 0.3;

CGFloat POPopupOverlayerMaxVisibleItems = 30;

@interface YRPopupOverlayerContainerView : UIView
@end
@implementation YRPopupOverlayerContainerView
@end

@interface POPopupOverlayer ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) NSMutableDictionary *mutableItemViews;

@property (nonatomic, strong) NSMutableSet *reusingItemViews;

@property (nonatomic, assign) NSUInteger numberOfItemViews;
@property (nonatomic, assign) NSUInteger numberOfVisibleItemViews;

@property (nonatomic, assign) CGSize itemViewSize;  // Default is content-size inseted -7;

@end

@implementation POPopupOverlayer

- (instancetype)init{
    if (self = [super init]) {
        [self _initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self _initialize];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self _layoutItemViews];
}

- (void)_layoutItemViews {
    
    self.itemViewSize = CGRectInset([self bounds], 7, 7).size;
    self.contentView.frame = [self bounds];
    
    // load unload item views
    [self _loadUnloadItemViews];
}

#pragma mark - private

- (void)_initialize{
    
    self.maxTranslation = CGSizeEqualToSize(CGSizeZero, [self bounds].size) ? CGSizeMake(100, 100) : [self bounds].size;
    self.mutableItemViews = [NSMutableDictionary dictionary];
    self.reusingItemViews = [NSMutableSet set];
    self.itemViewRotateAngle = 10 /180. * M_PI;
    self.numberOfVisibleItemViews = 3;
    self.allowBackToFront = YES;
    self.allowDirections = POPopupOverlayerAnimationDirectionTop | POPopupOverlayerAnimationDirectionBottom | POPopupOverlayerAnimationDirectionLeft | POPopupOverlayerAnimationDirectionRight;
    
    self.contentView = [UIView new];
    self.contentView.layer.masksToBounds = NO;
    
    [self addSubview:[self contentView]];
    [[self contentView] addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanGestureRecognizerChanged:)]];
}

- (void)_updateLayoutForItemViews:(NSArray *)itemViews{
    // update frame for loaded container views
    [itemViews enumerateObjectsUsingBlock:^(UIView *itemView, NSUInteger nIndex, BOOL * _Nonnull stop) {
        CGSize itemViewSize = [self itemViewSizeAtIndex:nIndex];
        [self _updatelayoutItemView:itemView size:itemViewSize];
        [self _rotateTransformItemView:itemView atIndex:nIndex progress:0];
    }];
}

- (void)_loadUnloadItemViews{
    // update number of visible items
    [self _updateNumberOfVisibleItemViews];
    
    //visible view indices
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:[self numberOfVisibleItemViews]];
    NSInteger translation = [self currentItemIndex];
    for (NSInteger nIndex = 0; nIndex < [self numberOfVisibleItemViews]; nIndex++) {
        [visibleIndices addObject:@([self clampedIndex:nIndex + translation])];
    }
    
    //remove offscreen views
    for (NSNumber *number in [[self mutableItemViews] allKeys]) {
        if (![visibleIndices containsObject:number]) {
            UIView *view = [self mutableItemViews][number];
            if ([number integerValue] > 0 && [number integerValue] < [self numberOfItemViews]) {
                [self queueReusingItemView:view];
            }
            [[view superview] removeFromSuperview];
            [[self mutableItemViews] removeObjectForKey:number];
        }
    }
    
    //add onscreen views
    NSMutableArray *itemViews = [NSMutableArray array];
    for (NSNumber *number in visibleIndices) {
        UIView *itemView = [self mutableItemViews][number];
        if (itemView == nil) {
            itemView = [self _loadItemViewAtIndex:[number integerValue]];
        }
        [itemViews addObject:itemView];
    }
    
    // update frame for loaded container views
    [self _updateLayoutForItemViews:itemViews];
}

/**
 *  load a item view into container view
 *
 *  @param nIndex index of item view
 *
 *  @return container view
 */
- (UIView *)_loadItemViewAtIndex:(NSUInteger)nIndex {
    return [self _loadItemViewAtIndex:nIndex withContainerView:nil];
}

/**
 *  load a item view into container view
 *
 *  @param nIndex index of item view
 *
 *  @param containerView container of item view at this index, it will create a new container view if this is nil.
 *
 *  @return container view
 */
- (UIView *)_loadItemViewAtIndex:(NSUInteger)nIndex withContainerView:(UIView *)containerView{
    NSParameterAssert(nIndex >= 0 && nIndex < [self numberOfItemViews]);
    
    UIView *itemView = [[self dataSource] popupOverlayer:self viewForItemAtIndex:nIndex reusingView:[self dequeueReusingItemView]];
    if (!itemView){
        itemView = [[UIView alloc] init];
    }
    
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:willDisplayItemView:atIndex:)]) {
        [[self delegate] popupOverlayer:self willDisplayItemView:itemView atIndex:nIndex];
    }
    
    CGSize itemViewSize = [self itemViewSizeAtIndex:nIndex];
    if (containerView) {
        //get old item view
        UIView *oldItemView = [[containerView subviews] lastObject];
        [self queueReusingItemView:oldItemView];
        //switch views
        [oldItemView removeFromSuperview];
        [containerView addSubview:itemView];
    } else {
        containerView = [self containerView:itemView];
        [self _insertSubviewWithContainerView:containerView atIndex:nIndex];
    }
    [self setItemView:itemView forIndex:nIndex];
    //set container frame
    [self _updatelayoutItemView:itemView size:itemViewSize];
    
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:willDisplayItemView:atIndex:)]) {
        [[self delegate] popupOverlayer:self willDisplayItemView:itemView atIndex:nIndex];
    }
    
    return itemView;
}

- (void)_insertSubviewWithContainerView:(UIView *)containerView atIndex:(NSUInteger)nIndex{
    NSArray *indexesForVisibleItemViews = [self indexesForVisibleItemViews];
    [indexesForVisibleItemViews enumerateObjectsUsingBlock:^(NSNumber *visibleIndex, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger nVisibleIndex = [visibleIndex integerValue];
        NSParameterAssert(nVisibleIndex != nIndex);
        if (nVisibleIndex > nIndex) {
            UIView *belowContainerView = [[self itemViewAtIndex:nVisibleIndex] superview];
            [[self contentView] insertSubview:containerView aboveSubview:belowContainerView];
            *stop = YES;
        }
    }];
    
    if (![containerView superview]) {
        UIView *mostBelowContainerView = [[self itemViewAtIndex:[[indexesForVisibleItemViews lastObject] integerValue]] superview];
        if (mostBelowContainerView) {
            [[self contentView] insertSubview:containerView belowSubview:mostBelowContainerView];
        } else {
            [[self contentView] addSubview:containerView];
        }
    }
}

- (void)_deleteAtIndex:(NSInteger)nIndex{
    UIView *itemView = [self mutableItemViews][@(nIndex)];
    if (itemView) {
        [self queueReusingItemView:itemView];
        [[self mutableItemViews] removeObjectForKey:@(nIndex)];
        [[itemView superview] removeFromSuperview];
    }
}

- (void)_removeItemViewAtIndex:(NSUInteger)nIndex {
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[[self mutableItemViews] count] - 1];
    for (NSNumber *number in [self indexesForVisibleItemViews]) {
        NSUInteger i = [number integerValue];
        if (i < nIndex) {
            newItemViews[number] = [self mutableItemViews][number];
        } else if (i > nIndex) {
            newItemViews[@(i - 1)] = [self mutableItemViews][number];
        }
    }
    self.mutableItemViews = newItemViews;
}

- (void)_insertItemView:(UIView *)view atIndex:(NSUInteger)nIndex {
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[[self mutableItemViews] count] + 1];
    for (NSNumber *number in [self indexesForVisibleItemViews]) {
        NSUInteger i = [number integerValue];
        if (i < nIndex) {
            newItemViews[number] = [self mutableItemViews][number];
        } else {
            newItemViews[@(i + 1)] = [self mutableItemViews][number];
        }
    }
    if (view) {
        newItemViews[@(nIndex)] = view;
    }
    self.mutableItemViews = newItemViews;
}

- (void)_restoreTransformExcludeIndex:(NSUInteger)excludeIndex animated:(BOOL)animated{
    [self _restoreTransformExcludeIndex:excludeIndex animated:animated completion:nil];
}

- (void)_restoreTransformExcludeIndex:(NSUInteger)excludeIndex animated:(BOOL)animated completion:(void (^)())completion{
    [self _rotateTransformExcludeIndex:excludeIndex indexOffset:0 progress:0 animated:animated completion:completion];
}

- (void)_rotateTransformExcludeIndex:(NSUInteger)excludeIndex progress:(CGFloat)progress animated:(BOOL)animated{
    [self _rotateTransformExcludeIndex:excludeIndex progress:progress animated:animated completion:nil];
}

- (void)_rotateTransformExcludeIndex:(NSUInteger)excludeIndex progress:(CGFloat)progress animated:(BOOL)animated completion:(void (^)())completion{
    [self _rotateTransformExcludeIndex:excludeIndex indexOffset:0 progress:progress animated:animated completion:completion];
}

- (void)_rotateTransformExcludeIndex:(NSUInteger)excludeIndex indexOffset:(NSInteger)indexOffset progress:(CGFloat)progress animated:(BOOL)animated{
    [self _rotateTransformExcludeIndex:excludeIndex indexOffset:indexOffset progress:progress
                              animated:animated completion:nil];
}

- (void)_rotateTransformExcludeIndex:(NSUInteger)excludeIndex indexOffset:(NSInteger)indexOffset progress:(CGFloat)progress animated:(BOOL)animated completion:(void (^)())completion{
    void (^transform)() = ^(){
        NSArray *indexesForVisibleItemViews = [self indexesForVisibleItemViews];
        NSUInteger numberOfItemViews = [self numberOfItemViews];
        NSUInteger currentIndex = [[indexesForVisibleItemViews firstObject] integerValue];
        for (NSNumber *index in indexesForVisibleItemViews) {
            if (excludeIndex != [index integerValue]) {
                UIView *itemView = [self itemViewAtIndex:[index integerValue]];
                
                NSInteger nextIndex = [index integerValue] + indexOffset;
                nextIndex = MAX(0, nextIndex);
                nextIndex = MIN(nextIndex, numberOfItemViews - 1);
                
                CGFloat angleAtIndex = [self angleAtIndex:[index integerValue] - currentIndex progress:0];
                CGFloat angleAtIndexOffset = [self angleAtIndex:nextIndex - currentIndex progress:0];
                CGFloat angle = angleAtIndex + (angleAtIndexOffset - angleAtIndex) * progress;
                
                itemView.superview.layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
            }
        }
    };
    if (animated) {
        [UIView animateWithDuration:POPopupOverlayerAnimationDuration animations:transform completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        transform();
        if (completion) {
            completion();
        }
    }
}

- (void)_rotateTransformItemView:(UIView *)itemView atIndex:(NSInteger)nIndex progress:(CGFloat)progress{
    //center view
    itemView.superview.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
    
    //enable/disable interaction
    itemView.superview.userInteractionEnabled = (nIndex == self.currentItemIndex);
    
    //account for retina
    itemView.superview.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    //return back
    itemView.superview.layer.autoreverses = NO;
    //calculate transform
    CATransform3D transform = [self transformAtIndex:nIndex progress:progress];
    
    //transform view
    itemView.superview.layer.transform = transform;
}

- (void)_restoreLayoutItemView:(UIView *)itemView animated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:POPopupOverlayerAnimationDuration animations:^{
            itemView.superview.layer.transform = CATransform3DIdentity;
        }];
    } else {
        itemView.superview.layer.transform = CATransform3DIdentity;
    }
}

- (void)_updateNumberOfVisibleItemViews{
    self.numberOfVisibleItemViews = MIN(POPopupOverlayerMaxVisibleItems, [self numberOfVisibleItemViews]);
    if ([[self dataSource] respondsToSelector:@selector(numberOfVisibleItemsInPopupOverlayerView:)]) {
        self.numberOfVisibleItemViews = [[self dataSource] numberOfVisibleItemsInPopupOverlayerView:self];
    }
    self.numberOfVisibleItemViews = MAX(0, MIN([self numberOfVisibleItemViews], [self numberOfItemViews] - [self currentItemIndex]));
}

- (void)_updatelayoutItemView:(UIView *)itemView size:(CGSize)size{
    //set container frame
    CGRect bounds = [self bounds];
    itemView.superview.layer.transform = CATransform3DIdentity;
    itemView.superview.frame = CGRectMake((CGRectGetWidth(bounds) - size.width) / 2., (CGRectGetHeight(bounds) - size.height) / 2., size.width, size.height);
    itemView.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)_willMoveCurrentItemViewAtIndex:(NSUInteger)nIndex{
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:willMoveItemAtIndex:)]) {
        [[self delegate] popupOverlayer:self willMoveItemAtIndex:nIndex];
    }
}

- (void)_movingCurrentItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex{
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:movingItemViewWithTranslation:atIndex:)]) {
        [[self delegate] popupOverlayer:self movingItemViewWithTranslation:translation atIndex:nIndex];
    }
}

- (void)_didMoveCurrentItemViewWithTranslation:(CGPoint)translation atIndex:(NSUInteger)nIndex{
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:didMoveItemViewWithTranslation:atIndex:)]) {
        [[self delegate] popupOverlayer:self didMoveItemViewWithTranslation:translation atIndex:nIndex];
    }
}

- (BOOL)_canMoveCurrentItemViewAtIndex:(NSUInteger)nIndex{
    if ([[self dataSource] respondsToSelector:@selector(popupOverlayer:canMoveItemViewAtIndex:)]) {
        return [[self dataSource] popupOverlayer:self canMoveItemViewAtIndex:nIndex];
    }
    return YES;
}

#pragma mark - accessor

- (CATransform3D)_transformForMoveOutItemView:(UIView *)itemView onDirection:(POPopupOverlayerAnimationDirection)direction{
    
    return [self _transformForMoveOutItemView:itemView translation:CGPointZero direction:direction];
}

- (CATransform3D)_transformForMoveOutItemView:(UIView *)itemView translation:(CGPoint)translation direction:(POPopupOverlayerAnimationDirection)direction{
    
    CATransform3D transform = CATransform3DIdentity;
    
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:itemViewTransformOnDirection:defaultTransform:)]) {
        transform = [[self delegate] popupOverlayer:self itemViewTransformOnDirection:direction defaultTransform:transform];
    }
    
    translation = [self defaultTransformAtTranslation:translation direction:direction];
    
    transform = CATransform3DTranslate(transform, translation.x, translation.y, 0);
    
    return transform;
}

- (CATransform3D)_transformForMovingItemView:(UIView *)itemView atTranslation:(CGPoint)translation{
    CATransform3D transform = CATransform3DTranslate(CATransform3DIdentity, translation.x, translation.y, 0);
    
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:itemViewTransformForTranslation:defaultTransform:)]) {
        return [[self delegate] popupOverlayer:self itemViewTransformForTranslation:translation defaultTransform:transform];
    }
    return transform;
}

- (CGFloat)_progressForMovingCurrentItemViewWithTranslation:(CGPoint)translation location:(CGPoint)location atIndex:(NSUInteger)nIndex;{
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:progressMovingItemViewWithTranslation:sizeForItemAtIndex:)]) {
        return [[self delegate] popupOverlayer:self progressMovingItemViewWithTranslation:translation sizeForItemAtIndex:nIndex];
    }
    return [self _defaultProgressWithTranslation:translation];
}

- (CGFloat)_defaultProgressWithTranslation:(CGPoint)translation{
    
    CGFloat distance = sqrt(powf(translation.x, 2) + powf(translation.y, 2));
    CGFloat maxDistance = sqrt(powf([self maxTranslation].width / 2., 2) + powf([self maxTranslation].width / 2., 2));
    
    if (maxDistance <= 0) {
        return 1.f;
    }
    return MIN(distance / maxDistance, 1);
}

- (CGPoint)defaultTransformAtTranslation:(CGPoint)translation direction:(POPopupOverlayerAnimationDirection)direction{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    CGPoint toTranslation = CGPointZero;
    CGSize  windowSize = [window bounds].size;
    CGPoint centerInWindow = [[self contentView] convertPoint:[[self contentView] center] toView:window];
    
    CGFloat scale = translation.y == 0 ? ((windowSize.width - centerInWindow.x) / (windowSize.height - centerInWindow.y)) : fabs(translation.x / translation.y);
    
    if (direction & POPopupOverlayerAnimationDirectionLeft && [self allowDirections] & POPopupOverlayerAnimationDirectionLeft) {
        toTranslation.x = -(windowSize.width - centerInWindow.x);
    }
    if (direction & POPopupOverlayerAnimationDirectionRight && [self allowDirections] & POPopupOverlayerAnimationDirectionRight) {
        toTranslation.x = (windowSize.width - centerInWindow.x);
    }
    
    if (direction & POPopupOverlayerAnimationDirectionTop && [self allowDirections] & POPopupOverlayerAnimationDirectionTop) {
        toTranslation.y = -fabs(MAX(1, fabs(toTranslation.x)) / scale);
    }
    if (direction & POPopupOverlayerAnimationDirectionBottom && [self allowDirections] & POPopupOverlayerAnimationDirectionBottom) {
        toTranslation.y = fabs(MAX(1, fabs(toTranslation.x)) / scale);
    }
    return toTranslation;
}

- (POPopupOverlayerAnimationDirection)directionAtTranslation:(CGPoint)translation{
    POPopupOverlayerAnimationDirection direction = POPopupOverlayerAnimationDirectionNone;
    if (translation.x > 5) {
        direction |= POPopupOverlayerAnimationDirectionRight;
    } else if (translation.x < -5) {
        direction |= POPopupOverlayerAnimationDirectionLeft;
    }
    if (translation.y > 5) {
        direction |= POPopupOverlayerAnimationDirectionBottom;
    } else if (translation.y < -5) {
        direction |= POPopupOverlayerAnimationDirectionTop;
    }
    return direction;
}

- (UIView *)containerView:(UIView *)itemView{
    UIView *containerView = [YRPopupOverlayerContainerView new];
    [containerView addSubview:itemView];
    return containerView;
}

- (NSArray *)indexesForVisibleItemViews {
    return [[[self mutableItemViews] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItemViews{
    return [[self mutableItemViews] objectsForKeys:[self indexesForVisibleItemViews] notFoundMarker:[NSNull null]];
}

- (UIView *)itemViewAtIndex:(NSUInteger)nIndex {
    return [self mutableItemViews][@(nIndex)];
}

- (NSUInteger)currentItemIndex{
    return [[[self indexesForVisibleItemViews] firstObject] integerValue];
}

- (UIView *)currentItemView {
    return [self itemViewAtIndex:self.currentItemIndex];
}

- (NSUInteger)indexOfItemView:(UIView *)itemView {
    NSUInteger nIndex = [[[self mutableItemViews] allValues] indexOfObject:itemView];
    if (nIndex != NSNotFound) {
        return [[[self mutableItemViews] allKeys][nIndex] integerValue];
    }
    return NSNotFound;
}

- (NSUInteger)indexOfItemViewOrSubview:(UIView *)view {
    NSUInteger nIndex = [self indexOfItemView:view];
    if (nIndex == NSNotFound && view != nil && view != self) {
        return [self indexOfItemViewOrSubview:view.superview];
    }
    return nIndex;
}

- (void)setItemView:(UIView *)itemView forIndex:(NSUInteger)nIndex {
    [self mutableItemViews][@(nIndex)] = itemView;
}

- (UIView *)dequeueReusingItemView {
    UIView *view = [[self reusingItemViews] anyObject];
    if (view) {
        [[self reusingItemViews] removeObject:view];
    }
    return view;
}

- (void)queueReusingItemView:(UIView *)reusingItemView {
    NSParameterAssert(reusingItemView);
    [[self reusingItemViews] addObject:reusingItemView];
}

- (NSUInteger)clampedIndex:(NSUInteger)index {
    if ([self numberOfItemViews] == 0) {
        return -1;
    } else {
        return MIN(MAX(0, index), MAX(0, [self numberOfItemViews] - 1));
    }
}

- (POPopupOverlayerAnimationDirection)adjustDirection:(POPopupOverlayerAnimationDirection)direction{
    if (direction == POPopupOverlayerAnimationDirectionRandom) {
        return 1 << (arc4random() % 4) | 1 << (arc4random() % 4);
    }
    return direction;
}

- (CGPoint)adjustTranslation:(CGPoint)translation;{
    if (![self allowDirections] & POPopupOverlayerAnimationDirectionLeft) {
        translation.x = MAX(translation.x, 0);
    }
    if (!([self allowDirections] & POPopupOverlayerAnimationDirectionRight)) {
        translation.x = MIN(translation.x, 0);
    }
    if (!([self allowDirections] & POPopupOverlayerAnimationDirectionTop)) {
        translation.y = MAX(translation.y, 0);
    }
    if (!([self allowDirections] & POPopupOverlayerAnimationDirectionBottom)) {
        translation.y = MIN(translation.y, 0);
    }
    return translation;
}

- (CGSize)itemViewSizeAtIndex:(NSUInteger)nIndex{
    CGSize itemViewSize = [self itemViewSize];
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:sizeForItemAtIndex:)]) {
        itemViewSize = [[self delegate] popupOverlayer:self sizeForItemAtIndex:nIndex];
    }
    return itemViewSize;
}

- (CATransform3D)transformAtIndex:(NSUInteger)nIndex progress:(CGFloat)progress{
    CGFloat angle = [self angleAtIndex:nIndex progress:progress];
    return CATransform3DMakeRotation(angle, 0, 0, 1);
}

- (CGFloat)angleAtIndex:(NSUInteger)nIndex progress:(CGFloat)progress{
    progress = MIN(progress, 1);
    progress = MAX(progress, 0);
    
    NSUInteger number = nIndex % [self numberOfVisibleItemViews];
    
    return pow(-1, number % 2 + 1) * ((number + 1) / 2) * [self itemViewRotateAngle] * (1 - progress);
}

#pragma mark - public

- (void)reloadData{
    //Remove old views
    for (UIView *view in [self visibleItemViews]){
        [[view superview] removeFromSuperview];
    }
    [[self mutableItemViews] removeAllObjects];
    [[self reusingItemViews] removeAllObjects];
    //Bail out if not set up yet
    if (![self dataSource]){
        return;
    }
    //Get number of items and placeholders
    self.numberOfItemViews = [[self dataSource] numberOfItemsInPopupOverlayerView:self];
    
    //layout views
    [self setNeedsLayout];
}

- (BOOL)popOverTopItemViewOnDirection:(POPopupOverlayerAnimationDirection)direction animated:(BOOL)animated;{
    
    return [self popOverTopItemViewAtTranslation:CGPointZero direction:direction animated:animated];
}

- (BOOL)popOverTopItemViewAtTranslation:(CGPoint)translation direction:(POPopupOverlayerAnimationDirection)direction  animated:(BOOL)animated;{
    NSInteger currentIndex = [self currentItemIndex];
    UIView *itemView = [self itemViewAtIndex:currentIndex];
    BOOL shouldPopupOver = YES;
    if ([[self delegate] respondsToSelector:@selector(popupOverlayer:shouldPopupOverItemView:direction:atIndex:)]) {
        shouldPopupOver = [[self delegate] popupOverlayer:self shouldPopupOverItemView:itemView direction:direction atIndex:currentIndex];
    }
    if (!shouldPopupOver) {
        [self _restoreTransformExcludeIndex:NSNotFound animated:YES];
        return NO;
    }
    
    BOOL allowBackToFront = [self allowBackToFront];
    
    void (^completion)() = ^{
        [self _deleteAtIndex:currentIndex];
        if ([self numberOfItemViews] - currentIndex - 1 > 0 || allowBackToFront) {
            [self _loadUnloadItemViews];
            [self _restoreTransformExcludeIndex:NSNotFound animated:NO];
        }
        if ([[self delegate] respondsToSelector:@selector(popupOverlayer:didPopupOverItemViewOnDirection:atIndex:)]) {
            [[self delegate] popupOverlayer:self didPopupOverItemViewOnDirection:direction atIndex:currentIndex];
        }
    };
    if (animated) {
        self.userInteractionEnabled = NO;
        //        itemView.superview.layer.transform = CATransform3DMakeTranslation(translation.x, translation.y, 0);
        CATransform3D transform = [self _transformForMoveOutItemView:itemView translation:translation direction:direction];
        [UIView animateWithDuration:POPopupOverlayerAnimationDuration animations:^{
            itemView.superview.alpha = 0;
            itemView.superview.layer.transform = transform;
        } completion:^(BOOL finished) {
            completion();
            self.userInteractionEnabled = YES;
        }];
    } else {
        completion();
    }
    return YES;
}

- (void)removeItemAtIndex:(NSUInteger)nIndex onDirection:(POPopupOverlayerAnimationDirection)direction animated:(BOOL)animated;{
    
    direction = [self adjustDirection:direction];
    nIndex = [self clampedIndex:nIndex];
    UIView *itemView = [self itemViewAtIndex:nIndex];
    
    if (animated) {
        self.userInteractionEnabled = NO;
        CATransform3D transform = [self _transformForMoveOutItemView:itemView onDirection:direction];
        [UIView animateWithDuration:POPopupOverlayerAnimationDuration animations:^{
            itemView.superview.layer.transform = transform;
        } completion:^(BOOL finished) {
            self.numberOfItemViews--;
            
            [self _deleteAtIndex:nIndex];
            [self _removeItemViewAtIndex:nIndex];
            [self _loadUnloadItemViews];
            [self _restoreTransformExcludeIndex:NSNotFound animated:YES];
            self.userInteractionEnabled = YES;
        }];
    } else {
        
        self.numberOfItemViews--;
        [self _deleteAtIndex:nIndex];
        [self _removeItemViewAtIndex:nIndex];
        [self _loadUnloadItemViews];
        [self _restoreTransformExcludeIndex:NSNotFound animated:NO];
    }
}

- (void)insertItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated {
    self.numberOfItemViews++;
    nIndex = [self clampedIndex:nIndex];
    [self _insertItemView:nil atIndex:nIndex];
    [self _loadItemViewAtIndex:nIndex];
    
    if (animated) {
        self.userInteractionEnabled = NO;
        [UIView animateWithDuration:POPopupOverlayerAnimationDuration animations:^{
            [self _restoreTransformExcludeIndex:NSNotFound animated:NO];
        } completion:^(BOOL finished) {
            [self _loadUnloadItemViews];
            self.userInteractionEnabled = YES;
        }];
    } else {
        [self _restoreTransformExcludeIndex:NSNotFound animated:NO];
        [self _loadUnloadItemViews];
    }
}

- (void)reloadItemAtIndex:(NSUInteger)nIndex animated:(BOOL)animated {
    //get container view
    UIView *containerView = [[self itemViewAtIndex:nIndex] superview];
    if (containerView) {
        if (animated) {
            //fade transition
            CATransition *transition = [CATransition animation];
            transition.duration = POPopupOverlayerAnimationDuration;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [containerView.layer addAnimation:transition forKey:nil];
        }
        //reload view
        [self _loadItemViewAtIndex:nIndex withContainerView:containerView];
    } else {
        [self _loadItemViewAtIndex:nIndex withContainerView:nil];
        [self _restoreTransformExcludeIndex:NSNotFound animated:YES];
        [self _loadUnloadItemViews];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;{
    return [self _canMoveCurrentItemViewAtIndex:[self currentItemIndex]];
}

#pragma mark - actions

- (IBAction)didPanGestureRecognizerChanged:(UIPanGestureRecognizer *)panGestureRecognizer{
    NSUInteger currentIndex = [self currentItemIndex];
    UIView *itemView = [self itemViewAtIndex:currentIndex];
    if (!itemView) {
        return;
    }
    CGPoint location = [panGestureRecognizer locationInView:self];
    CGPoint translation = [panGestureRecognizer translationInView:self];
    CGPoint limitTranslation = [self adjustTranslation:translation];
    
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            [self _willMoveCurrentItemViewAtIndex:currentIndex];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat progress = [self _progressForMovingCurrentItemViewWithTranslation:limitTranslation location:location atIndex:currentIndex];
            
            [self _rotateTransformExcludeIndex:currentIndex indexOffset:-1 progress:progress animated:NO];
            
            itemView.superview.layer.transform = [self _transformForMovingItemView:itemView atTranslation:limitTranslation];
            
            [self _movingCurrentItemViewWithTranslation:limitTranslation atIndex:currentIndex];
        }   break;
        case UIGestureRecognizerStateEnded:
        {
            if ([self _defaultProgressWithTranslation:limitTranslation] > 0.5) {
                [self popOverTopItemViewAtTranslation:translation direction:[self directionAtTranslation:limitTranslation] animated:YES];
                
            } else {
                self.userInteractionEnabled = NO;
                [self _restoreTransformExcludeIndex:NSNotFound animated:YES completion:^{
                    self.userInteractionEnabled = YES;
                }];
            }
            [self _didMoveCurrentItemViewWithTranslation:limitTranslation atIndex:currentIndex];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            self.userInteractionEnabled = NO;
            [self _restoreTransformExcludeIndex:NSNotFound animated:YES completion:^{
                self.userInteractionEnabled = YES;
            }];
        }
            break;
        default:
            break;
    }
}

@end
