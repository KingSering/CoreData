//
//  GmDataManager.m
//  YuanDong
//
//  Created by king on 2024/5/29.
//
#import "GmDataManager.h"
@implementation GmDataManager
#pragma mark - Core Data stack
@synthesize managedObjectContext = _managedObjectContext;

+ (instancetype)sharedManager {
    static GmDataManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        // 创建上下文对象，并发队列设置为主队列
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        // 上下文对象设置属性为持久化存储器
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    // 创建托管对象模型，并使用Student.momd路径当做初始化参数
    // .xcdatamodeld文件 编译之后变成.momd文件  （.mom文件）
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Gm001Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    // 创建持久化存储调度器
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    /**
     这里说一下新增加的2个参数的意义： NSMigratePersistentStoresAutomaticallyOption = YES，那么Core Data会试着把之前低版本的出现不兼容的持久化存储区迁移到新的模型中，这里的例子里，Core Data就能识别出是新表，就会新建出新表的存储区来，上面就不会报上面的error了。
     NSInferMappingModelAutomaticallyOption = YES,这个参数的意义是Core Data会根据自己认为最合理的方式去尝试MappingModel，从源模型实体的某个属性，映射到目标模型实体的某个属性。
     */
    NSDictionary *options =
        @{
          NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"},
          NSMigratePersistentStoresAutomaticallyOption :@YES,
          NSInferMappingModelAutomaticallyOption:@NO// YES 自动迁移 NO 手动迁移
        };
 
    // 创建并关联SQLite数据库文件，如果已经存在则不会重复创建
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Gm001Model.sqlite"];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        
        // 数据迁移失败，尝试手动迁移 NSInferMappingModelAutomaticallyOption @NO
                [self manualMigrationWithOptions:options storeURL:storeURL error:&error];
                
                if (error) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
        
    }
    return _persistentStoreCoordinator;
}
- (void)saveContext;
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)manualMigrationWithOptions:(NSDictionary *)options storeURL:(NSURL *)storeURL error:(NSError **)error {
    // 创建托管对象模型
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:nil];
    
    // 创建源和目标数据库并进行迁移
    NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:nil forSourceModel:sourceModel destinationModel:self.managedObjectModel];
    
    if (mappingModel != nil && sourceModel != nil) {
        NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:self.managedObjectModel];
        
        // 创建目标数据库文件
        NSURL *destStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Gm001Model1.sqlite"];
        if ([migrationManager migrateStoreFromURL:storeURL type:NSSQLiteStoreType options:options withMappingModel:mappingModel toDestinationURL:destStoreURL destinationType:NSSQLiteStoreType destinationOptions:options error:error]) {
            // 迁移成功，删除旧的数据库文件，将新数据库文件重命名为原文件名
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
            [[NSFileManager defaultManager] moveItemAtURL:destStoreURL toURL:storeURL error:nil];
        } else {
            // 迁移失败，删除新数据库文件
            [[NSFileManager defaultManager] removeItemAtURL:destStoreURL error:nil];
        }
    } else {
        NSLog(@"Cannot create an NSMigrationManager with a nil source model");
    }
}

@end
