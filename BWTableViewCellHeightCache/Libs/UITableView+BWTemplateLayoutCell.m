//
//  UITableView+BWTemplateLayoutCell.m
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import "UITableView+BWTemplateLayoutCell.h"
#import <objc/runtime.h>
#import "UITableView+BWIndexPathHeightCache.h"

@implementation UITableView (BWTemplateLayoutCell)


- (BOOL)bw_debugLogEnabled {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (CGFloat)bw_heightForCellWithIdentifier:(NSString *)identifier cacheByIndexPath:(NSIndexPath *)indexPath configuration:(void (^)(id cell))configuration {
    if (!identifier || !indexPath) {
        return 0;
    }
    
    // 如果命中缓存，采用缓存
    if ([self.bw_indexPathHeightCache existsHeightAtIndexPath:indexPath]) {
        [self bw_debugLog:[NSString stringWithFormat:@"hit cache by index path[%@:%@] - %@", @(indexPath.section), @(indexPath.row), @([self.bw_indexPathHeightCache heightForIndexPath:indexPath])]];
        // 读取缓存
        return [self.bw_indexPathHeightCache heightForIndexPath:indexPath];
    }
    
    CGFloat height = [self bw_heightForCellWithIdentifier:identifier configuration:configuration];
    [self.bw_indexPathHeightCache cacheHeight:height byIndexPath:indexPath];
    [self bw_debugLog:[NSString stringWithFormat: @"cached by index path[%@:%@] - %@", @(indexPath.section), @(indexPath.row), @(height)]];
    
    return height;
}
- (CGFloat)bw_heightForCellWithIdentifier:(NSString *)identifier configuration:(void (^)(id cell))configuration {
    if (!identifier) {
        return 0;
    }
    UITableViewCell *templateLayoutCell = [self bw_templateCellForReuseIdentifier:identifier];
    // 准备重用，不加的话会导致错乱
    [templateLayoutCell prepareForReuse];
    if (configuration) {
        configuration(templateLayoutCell);
    }
    return [self bw_systemFittingHeightForConfiguratedCell:templateLayoutCell];
}

// 这里用来计算高度嘛
- (CGFloat)bw_systemFittingHeightForConfiguratedCell:(UITableViewCell *)cell {
    CGFloat contentViewWidth = CGRectGetWidth(self.frame);
    CGRect cellBounds = cell.bounds;
    cellBounds.size.width = contentViewWidth;
    cell.bounds = cellBounds;
    CGFloat rightSystemViewsWidth = 0.0;
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITableViewIndex")]) {
            rightSystemViewsWidth = CGRectGetWidth(view.frame);
            break;
        }
    }
    // 如果设置箭头，将重新计算
    if (cell.accessoryView) {
        rightSystemViewsWidth += 16 + CGRectGetWidth(cell.accessoryView.frame);
    } else {
        static const CGFloat systemAccessoryWidths[] = {
            [UITableViewCellAccessoryNone] = 0,
            [UITableViewCellAccessoryDisclosureIndicator] = 34,
            [UITableViewCellAccessoryDetailDisclosureButton] = 68,
            [UITableViewCellAccessoryCheckmark] = 40,
            [UITableViewCellAccessoryDetailButton] = 48
        };
        rightSystemViewsWidth += systemAccessoryWidths[cell.accessoryType];
    }
    
    if ([UIScreen mainScreen].scale >= 3 && [UIScreen mainScreen].bounds.size.width >= 414) {
        rightSystemViewsWidth += 4;
    }
    
    contentViewWidth -= rightSystemViewsWidth;

    
    // If not using auto layout, you have to override "-sizeThatFits:" to provide a fitting size by yourself.
    // This is the same height calculation passes used in iOS8 self-sizing cell's implementation.
    //
    // 1. Try "- systemLayoutSizeFittingSize:" first. (skip this step if 'bw_enforceFrameLayout' set to YES.)
    // 2. Warning once if step 1 still returns 0 when using AutoLayout
    // 3. Try "- sizeThatFits:" if step 1 returns 0
    // 4. Use a valid height or default row height (44) if not exist one
    
    CGFloat fittingHeight = 0;
    
    if (!cell.bw_enforceFrameLayout && contentViewWidth > 0) {
        // Add a hard width constraint to make dynamic content views (like labels) expand vertically instead
        // of growing horizontally, in a flow-layout manner.
        NSLayoutConstraint *widthFenceConstraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:contentViewWidth];

        // [bug fix] after iOS 10.3, Auto Layout engine will add an additional 0 width constraint onto cell's content view, to avoid that, we add constraints to content view's left, right, top and bottom.
        static BOOL isSystemVersionEqualOrGreaterThen10_2 = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            isSystemVersionEqualOrGreaterThen10_2 = [UIDevice.currentDevice.systemVersion compare:@"10.2" options:NSNumericSearch] != NSOrderedAscending;
        });
        
        NSArray<NSLayoutConstraint *> *edgeConstraints;
        if (isSystemVersionEqualOrGreaterThen10_2) {
            // To avoid confilicts, make width constraint softer than required (1000)
            widthFenceConstraint.priority = UILayoutPriorityRequired - 1;
            
            // Build edge constraints
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeRight multiplier:1.0 constant:-rightSystemViewsWidth];
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:cell.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
            edgeConstraints = @[leftConstraint, rightConstraint, topConstraint, bottomConstraint];
            [cell addConstraints:edgeConstraints];
        }
        
        [cell.contentView addConstraint:widthFenceConstraint];

        // Auto layout engine does its math
        fittingHeight = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        
        // Clean-ups
        [cell.contentView removeConstraint:widthFenceConstraint];
        if (isSystemVersionEqualOrGreaterThen10_2) {
            [cell removeConstraints:edgeConstraints];
        }
        
        [self bw_debugLog:[NSString stringWithFormat:@"calculate using system fitting size (AutoLayout) - %@", @(fittingHeight)]];
    }
    
    if (fittingHeight == 0) {
#if DEBUG
        // Warn if using AutoLayout but get zero height.
        if (cell.contentView.constraints.count > 0) {
            if (!objc_getAssociatedObject(self, _cmd)) {
                NSLog(@"[FDTemplateLayoutCell] Warning once only: Cannot get a proper cell height (now 0) from '- systemFittingSize:'(AutoLayout). You should check how constraints are built in cell, making it into 'self-sizing' cell.");
                objc_setAssociatedObject(self, _cmd, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
#endif
        // Try '- sizeThatFits:' for frame layout.
        // Note: fitting height should not include separator view.
        fittingHeight = [cell sizeThatFits:CGSizeMake(contentViewWidth, 0)].height;
        
        [self bw_debugLog:[NSString stringWithFormat:@"calculate using sizeThatFits - %@", @(fittingHeight)]];
    }
    
    // Still zero height after all above.
    if (fittingHeight == 0) {
        // Use default row height.
        fittingHeight = 44;
    }
    
    // Add 1px extra space for separator line if needed, simulating default UITableViewCell.
    if (self.separatorStyle != UITableViewCellSeparatorStyleNone) {
        fittingHeight += 1.0 / [UIScreen mainScreen].scale;
    }
    
    return fittingHeight;
}
// 这里做啥用，返回cell
- (__kindof UITableViewCell *)bw_templateCellForReuseIdentifier:(NSString *)identifier {
    NSAssert(identifier.length > 0, @"Expect a valid identifier - %@", identifier);
    
    NSMutableDictionary<NSString *, UITableViewCell *> *templateCellsByIdentifiers = objc_getAssociatedObject(self, _cmd);
    if (!templateCellsByIdentifiers) {
        templateCellsByIdentifiers = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, templateCellsByIdentifiers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UITableViewCell *templateCell = templateCellsByIdentifiers[identifier];
    
    if (!templateCell) {
        templateCell = [self dequeueReusableCellWithIdentifier:identifier];
        NSAssert(templateCell != nil, @"Cell must be registered to table view for identifier - %@", identifier);
        templateCell.bw_isTemplateLayoutCell = YES;
        templateCell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        templateCellsByIdentifiers[identifier] = templateCell;
        [self bw_debugLog:[NSString stringWithFormat:@"layout cell created - %@", identifier]];
    }
    
    return templateCell;
}
- (void)bw_debugLog:(NSString *)message {
    if (self.bw_debugLogEnabled) {
        NSLog(@"** FDTemplateLayoutCell ** %@", message);
    }
}
@end



@implementation UITableViewCell (BWTemplateLayoutCell)

- (BOOL)bw_isTemplateLayoutCell {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBw_isTemplateLayoutCell:(BOOL)isTemplateLayoutCell {
    objc_setAssociatedObject(self, @selector(bw_isTemplateLayoutCell), @(isTemplateLayoutCell), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bw_enforceFrameLayout {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBw_enforceFrameLayout:(BOOL)enforceFrameLayout {
    objc_setAssociatedObject(self, @selector(bw_enforceFrameLayout), @(enforceFrameLayout), OBJC_ASSOCIATION_RETAIN);
}

@end
