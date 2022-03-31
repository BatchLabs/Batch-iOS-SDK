//
//  BAMSGStackView.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGStackView.h>

@implementation BAMSGStackView {
    NSMutableArray<BAMSGStackViewItem *> *items;
    int separatorCount;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        items = [NSMutableArray new];
        separatorCount = 0;
        self.horizontal = false;
    }
    return self;
}

- (void)addItem:(nonnull BAMSGStackViewItem *)item {
    item = [self rotatedItemForItem:item];

    BAMSGStackViewItem *separator = nil;

    // Automatically add the first separator if needed, and inject it as the previous view.
    if ([items count] == 0) {
        separator = [self separatorForItem:nil];
        [self addSeparatorItem:separator];
    }

    item.parentView = self;
    item.previousView = [items lastObject].view;
    item.view.translatesAutoresizingMaskIntoConstraints = false;

    if ([item.view conformsToProtocol:@protocol(BAMSGStylableView)]) {
        [(id<BAMSGStylableView>)item.view applyRules:item.rules];
    }

    [self addSubview:item.view];
    [items addObject:item];

    // Automatically add the next separator beforehand. We need to do that once the subview is already in the view
    // though, or else autolayout will break since the view isn't in the hierarchy yet

    // Since the StackView isn't aware of the styling system, we will have to ask our delegate for the rules
    separator = [self separatorForItem:item];
    item.nextView = separator.view;
    [self addSeparatorItem:separator];

    [self addConstraints:[item computeConstraints]];
}

- (void)sizeAllItemsEqually {
    NSLayoutAttribute equalAttribute = self.horizontal ? NSLayoutAttributeWidth : NSLayoutAttributeHeight;

    UIView *baseView = nil;
    for (BAMSGStackViewItem *item in items) {
        if ([item.view isKindOfClass:[BAMSGStackSeparatorView class]]) {
            continue;
        }

        if (!baseView) {
            baseView = item.view;
            continue;
        }

        [self addConstraint:[NSLayoutConstraint constraintWithItem:item.view
                                                         attribute:equalAttribute
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:baseView
                                                         attribute:equalAttribute
                                                        multiplier:1.0
                                                          constant:0.0]];
    }
}

- (NSArray<BAMSGStackViewItem *> *)items {
    return [NSArray arrayWithArray:items];
}

#pragma mark Private methods

- (void)addSeparatorItem:(nonnull BAMSGStackViewItem *)item {
    item.parentView = self;
    item.nextView = nil;
    item.view.translatesAutoresizingMaskIntoConstraints = false;
    [BAMSGStylableViewHelper applyCommonRules:item.rules toView:item.view];

    [self addSubview:item.view];

    [self addConstraints:[item computeConstraints]];

    [items addObject:item];

    separatorCount++;
}

- (BAMSGStackViewItem *)rotatedItemForItem:(BAMSGStackViewItem *)item {
    if (!self.horizontal || !item) {
        return item;
    }

    BAMSGStackViewItem *rotatedItem = [BAMSGStackViewHorizontalItem new];
    rotatedItem.rules = item.rules;
    rotatedItem.view = item.view;
    rotatedItem.attachToParentBottom = item.attachToParentBottom;
    return rotatedItem;
}

- (BAMSGStackViewItem *)separatorForItem:(BAMSGStackViewItem *)item {
    BAMSGStackViewItem *separator = nil;

    if (self.horizontal) {
        separator = [BAMSGStackViewHorizontalSeparatorItem new];
    } else {
        separator = [BAMSGStackViewSeparatorItem new];
    }

    separator.view = [BAMSGStackSeparatorView new];
    separator.view.translatesAutoresizingMaskIntoConstraints = NO;

    if (item) {
        separator.attachToParentBottom = item.attachToParentBottom;
        separator.previousView = item.view;
    }

    // Read the rules from the delegate, if we can
    if ([self.delegate respondsToSelector:@selector(stackView:rulesForSeparatorID:)] &&
        [self.delegate respondsToSelector:@selector(separatorPrefixForStackView:)]) {
        NSString *separatorID =
            [NSString stringWithFormat:@"%@-sep-%d", [self.delegate separatorPrefixForStackView:self], separatorCount];
        separator.rules = [self.delegate stackView:self rulesForSeparatorID:separatorID];
    }

    return separator;
}

@end

@implementation BAMSGStackSeparatorView

- (CGSize)intrinsicContentSize {
    // We return a intrinsic width of 10, to help integration: adding "height: 10" and no width doesn't make the view
    // appear, which gets quite confusing: setting a default width helps figure out that the width rule is missing. We
    // return a 0 intrinsic height so that separators are hidden by default
    return CGSizeMake(10, 0);
}

@end
