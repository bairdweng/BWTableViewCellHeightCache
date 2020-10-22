//
//  UITableView+BWIndexPathHeightCache.m
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import "UITableView+BWIndexPathHeightCache.h"
#import <objc/runtime.h>

@implementation UITableView (BWIndexPathHeightCache)
- (BWIndexPathHeightCache *)bw_indexPathHeightCache {
    BWIndexPathHeightCache *cache = objc_getAssociatedObject(self, _cmd);
    if (!cache) {
        cache = [BWIndexPathHeightCache new];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

@end


// We just forward primary call, in crash report, top most method in stack maybe FD's,
// but it's really not our bug, you should check whether your table view's data source and
// displaying cells are not matched when reloading.
static void __FD_TEMPLATE_LAYOUT_CELL_PRIMARY_CALL_IF_CRASH_NOT_OUR_BUG__(void (^callout)(void)) {
    callout();
}
#define FDPrimaryCall(...) do {__FD_TEMPLATE_LAYOUT_CELL_PRIMARY_CALL_IF_CRASH_NOT_OUR_BUG__(^{__VA_ARGS__});} while(0)

@implementation UITableView (FDIndexPathHeightCacheInvalidation)

- (void)bw_reloadDataWithoutInvalidateIndexPathHeightCache {
    FDPrimaryCall([self bw_reloadData];);
}
+ (void)load {
    // All methods that trigger height cache's invalidation
    SEL selectors[] = {
        @selector(reloadData),
        @selector(insertSections:withRowAnimation:),
        @selector(deleteSections:withRowAnimation:),
        @selector(reloadSections:withRowAnimation:),
        @selector(moveSection:toSection:),
        @selector(insertRowsAtIndexPaths:withRowAnimation:),
        @selector(deleteRowsAtIndexPaths:withRowAnimation:),
        @selector(reloadRowsAtIndexPaths:withRowAnimation:),
        @selector(moveRowAtIndexPath:toIndexPath:)
    };
    
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
        SEL originalSelector = selectors[index];
        SEL swizzledSelector = NSSelectorFromString([@"bw_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}
// hook刷新
- (void)bw_reloadData {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
            [heightsBySection removeAllObjects];
        }];
    }
    FDPrimaryCall([self bw_reloadData];);
}
- (void)bw_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
            [self.bw_indexPathHeightCache buildSectionsIfNeeded:section];
            [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
                [heightsBySection insertObject:[NSMutableArray array] atIndex:section];
            }];
        }];
    }
    FDPrimaryCall([self bw_insertSections:sections withRowAnimation:animation];);
}

- (void)bw_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
            [self.bw_indexPathHeightCache buildSectionsIfNeeded:section];
            [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
                [heightsBySection removeObjectAtIndex:section];
            }];
        }];
    }
    FDPrimaryCall([self bw_deleteSections:sections withRowAnimation:animation];);
}

- (void)bw_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [sections enumerateIndexesUsingBlock: ^(NSUInteger section, BOOL *stop) {
            [self.bw_indexPathHeightCache buildSectionsIfNeeded:section];
            [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
                [heightsBySection[section] removeAllObjects];
            }];

        }];
    }
    FDPrimaryCall([self bw_reloadSections:sections withRowAnimation:animation];);
}

- (void)bw_moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.bw_indexPathHeightCache buildSectionsIfNeeded:section];
        [self.bw_indexPathHeightCache buildSectionsIfNeeded:newSection];
        [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
            [heightsBySection exchangeObjectAtIndex:section withObjectAtIndex:newSection];
        }];
    }
    FDPrimaryCall([self bw_moveSection:section toSection:newSection];);
}

- (void)bw_insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.bw_indexPathHeightCache buildCachesAtIndexPathsIfNeeded:indexPaths];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
                [heightsBySection[indexPath.section] insertObject:@-1 atIndex:indexPath.row];
            }];
        }];
    }
    FDPrimaryCall([self bw_insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];);
}

- (void)bw_deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.bw_indexPathHeightCache buildCachesAtIndexPathsIfNeeded:indexPaths];
        
        NSMutableDictionary<NSNumber *, NSMutableIndexSet *> *mutableIndexSetsToRemove = [NSMutableDictionary dictionary];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            NSMutableIndexSet *mutableIndexSet = mutableIndexSetsToRemove[@(indexPath.section)];
            if (!mutableIndexSet) {
                mutableIndexSet = [NSMutableIndexSet indexSet];
                mutableIndexSetsToRemove[@(indexPath.section)] = mutableIndexSet;
            }
            [mutableIndexSet addIndex:indexPath.row];
        }];
        
        [mutableIndexSetsToRemove enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSIndexSet *indexSet, BOOL *stop) {
            [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
                [heightsBySection[key.integerValue] removeObjectsAtIndexes:indexSet];
            }];
        }];
    }
    FDPrimaryCall([self bw_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];);
}

- (void)bw_reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.bw_indexPathHeightCache buildCachesAtIndexPathsIfNeeded:indexPaths];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
                heightsBySection[indexPath.section][indexPath.row] = @-1;
            }];
        }];
    }
    FDPrimaryCall([self bw_reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];);
}

- (void)bw_moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (self.bw_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.bw_indexPathHeightCache buildCachesAtIndexPathsIfNeeded:@[sourceIndexPath, destinationIndexPath]];
        [self.bw_indexPathHeightCache enumerateAllOrientationsUsingBlock:^(BWIndexPathHeightsBySection *heightsBySection) {
            NSMutableArray<NSNumber *> *sourceRows = heightsBySection[sourceIndexPath.section];
            NSMutableArray<NSNumber *> *destinationRows = heightsBySection[destinationIndexPath.section];
            NSNumber *sourceValue = sourceRows[sourceIndexPath.row];
            NSNumber *destinationValue = destinationRows[destinationIndexPath.row];
            sourceRows[sourceIndexPath.row] = destinationValue;
            destinationRows[destinationIndexPath.row] = sourceValue;
        }];
    }
    FDPrimaryCall([self bw_moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];);
}
@end
