//
//  UITableView+BWTemplateLayoutCell.h
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import <UIKit/UIKit.h>
#import "UITableView+BWLayoutCellDebug.h"
NS_ASSUME_NONNULL_BEGIN

@interface UITableView (BWTemplateLayoutCell)
// 自动计算cell的高度，此方法不采用缓存
- (CGFloat)bw_heightForCellWithIdentifier:(NSString *)identifier configuration:(void (^)(id cell))configuration;
// 该方法采用了缓存
- (CGFloat)bw_heightForCellWithIdentifier:(NSString *)identifier cacheByIndexPath:(NSIndexPath *)indexPath configuration:(void (^)(id cell))configuration;
@end
@interface UITableViewCell (BWTemplateLayoutCell)
@property (nonatomic, assign) BOOL bw_isTemplateLayoutCell;
@property (nonatomic, assign) BOOL bw_enforceFrameLayout;

@end
NS_ASSUME_NONNULL_END
