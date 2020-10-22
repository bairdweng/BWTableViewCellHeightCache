//
//  UITableView+BWLayoutCellDebug.h
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (BWLayoutCellDebug)
@property (nonatomic, assign) BOOL bw_debugLogEnabled;
- (void)bw_debugLog:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
