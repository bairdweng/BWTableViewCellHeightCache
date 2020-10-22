//
//  BWIndexPathHeightCache.h
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NSMutableArray<NSMutableArray * > BWIndexPathHeightsBySection;

@interface BWIndexPathHeightCache : NSObject
// Enable automatically if you're using index path driven height cache
@property (nonatomic, assign) BOOL automaticallyInvalidateEnabled;

@property (nonatomic, strong) BWIndexPathHeightCache *heightsBySectionForPortrait;
@property (nonatomic, strong) BWIndexPathHeightCache *heightsBySectionForLandscape;
// Height cache
- (BOOL)existsHeightAtIndexPath:(NSIndexPath *)indexPath;
- (void)cacheHeight:(CGFloat)height byIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForIndexPath:(NSIndexPath *)indexPath;
- (void)invalidateHeightAtIndexPath:(NSIndexPath *)indexPath;
- (void)invalidateAllHeightCache;
- (void)enumerateAllOrientationsUsingBlock:(void (^)(BWIndexPathHeightsBySection *heightsBySection))block;
- (void)buildSectionsIfNeeded:(NSInteger)targetSection;
- (void)buildCachesAtIndexPathsIfNeeded:(NSArray *)indexPaths;
- (void)buildRowsIfNeeded:(NSInteger)targetRow inExistSection:(NSInteger)section;
@end

NS_ASSUME_NONNULL_END
