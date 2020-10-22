//
//  UITableView+BWIndexPathHeightCache.h
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import <UIKit/UIKit.h>
#import "BWIndexPathHeightCache.h"
NS_ASSUME_NONNULL_BEGIN

@interface UITableView (BWIndexPathHeightCache)
@property (nonatomic, strong, readonly) BWIndexPathHeightCache *bw_indexPathHeightCache;

@end

NS_ASSUME_NONNULL_END


@interface UITableView (FDIndexPathHeightCacheInvalidation)
/// Call this method when you want to reload data but don't want to invalidate
/// all height cache by index path, for example, load more data at the bottom of
/// table view.
- (void)bw_reloadDataWithoutInvalidateIndexPathHeightCache;
@end
