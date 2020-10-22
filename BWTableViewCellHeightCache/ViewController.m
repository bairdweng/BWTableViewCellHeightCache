//
//  ViewController.m
//  BWTableViewCellHeightCache
//
//  Created by bairdweng on 2020/10/22.
//

#import "ViewController.h"
#import "CacheTableViewCell.h"
#import "BWFeedEntity.h"
#import "TestTableViewCell.h"
#import "UITableView+BWTemplateLayoutCell.h"
static NSString * cellID = @"test_cell_id";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *feedEntitySections; // 2d array
@property (nonatomic, copy) NSArray *prototypeEntitiesFromJSON;
@property (weak, nonatomic) IBOutlet UITableView *dataTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.dataTableView registerNib:[UINib nibWithNibName:@"CacheTableViewCell" bundle:nil] forCellReuseIdentifier:cellID];
    
    self.dataTableView.bw_debugLogEnabled = YES;
    self.dataTableView.delegate = self;
    self.dataTableView.dataSource = self;
    [self buildTestDataThen:^{
        self.feedEntitySections = @[].mutableCopy;
        [self.feedEntitySections addObject:self.prototypeEntitiesFromJSON.mutableCopy];
        [self.dataTableView reloadData];
    }];
    // Do any additional setup after loading the view.
}

- (IBAction)addRow:(id)sender {
    [self insertRow];
}

- (IBAction)deleteRow:(id)sender {
    [self deleteSection];
}



- (void)deleteSection {
    if (self.feedEntitySections.count > 0) {
        [self.feedEntitySections removeObjectAtIndex:0];
        [self.dataTableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}



// 随机实体
- (BWFeedEntity *)randomEntity {
    NSUInteger randomNumber = arc4random_uniform((int32_t)self.prototypeEntitiesFromJSON.count);
    BWFeedEntity *randomEntity = self.prototypeEntitiesFromJSON[randomNumber];
    return randomEntity;
}

- (void)insertRow {
    if (self.feedEntitySections.count == 0) {
        [self insertSection];
    } else {
        [self.feedEntitySections[0] insertObject:self.randomEntity atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.dataTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
- (void)insertSection {
    [self.feedEntitySections insertObject:@[self.randomEntity].mutableCopy atIndex:0];
    [self.dataTableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (void)buildTestDataThen:(void (^)(void))then {
    // Simulate an async request
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          // Data from `data.json`
          NSString *dataFilePath =
              [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
          NSData *data = [NSData dataWithContentsOfFile:dataFilePath];
          NSDictionary *rootDict = [NSJSONSerialization
              JSONObjectWithData:data
                         options:NSJSONReadingAllowFragments
                           error:nil];
          NSArray *feedDicts = rootDict[@"feed"];

          // Convert to `FDFeedEntity`
          NSMutableArray *entities = @[].mutableCopy;
          [feedDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx,
                                                  BOOL *stop) {
            [entities addObject:[[BWFeedEntity alloc] initWithDictionary:obj]];
          }];
          self.prototypeEntitiesFromJSON = entities;

          // Callback
          dispatch_async(dispatch_get_main_queue(), ^{
            !then ?: then();
          });
        });
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    CacheTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return  cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.feedEntitySections.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.feedEntitySections[section] count];

}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return @[@"A",@"B",@"C",@"D"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 不加缓存高度的写法
//    return [tableView bw_heightForCellWithIdentifier:cellID configuration:^(CacheTableViewCell *cell) {
//        [self configureCell:cell atIndexPath:indexPath];
//    }];
    
    // 写入缓存的写法
    return [tableView bw_heightForCellWithIdentifier:cellID cacheByIndexPath:indexPath configuration:^(id  _Nonnull cell) {
        [self configureCell:cell atIndexPath:indexPath];
    }];
}

- (void)configureCell:(CacheTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.bw_enforceFrameLayout = NO; // Enable to use "-sizeThatFits:"
    if (indexPath.row % 2 == 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.entity = self.feedEntitySections[indexPath.section][indexPath.row];
}

@end
