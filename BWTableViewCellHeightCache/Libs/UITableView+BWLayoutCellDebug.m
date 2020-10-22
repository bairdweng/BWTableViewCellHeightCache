//
//  UITableView+BWLayoutCellDebug.m
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import "UITableView+BWLayoutCellDebug.h"
#import <objc/runtime.h>

@implementation UITableView (BWLayoutCellDebug)
- (BOOL)bw_debugLogEnabled {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBw_debugLogEnabled:(BOOL)debugLogEnabled {
    objc_setAssociatedObject(self, @selector(bw_debugLogEnabled), @(debugLogEnabled), OBJC_ASSOCIATION_RETAIN);
}



- (void)bw_debugLog:(NSString *)message {
    if (self.bw_debugLogEnabled) {
        NSLog(@"** FDTemplateLayoutCell ** %@", message);
    }
}

@end
