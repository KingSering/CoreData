//
//  GmDataManager.h
//  YuanDong
//
//  Created by king on 2024/5/29.
//

#import <Foundation/Foundation.h>

//
#import <CoreData/CoreData.h>

//
#import "GmHeartRate+CoreDataClass.h"
#import "GmHeartRate+CoreDataProperties.h"

#import "GmBloodOxygen+CoreDataClass.h"
#import "GmBloodOxygen+CoreDataProperties.h"





@interface GmDataManager : NSObject

/**
  对象管理上下文：负责管理模型的对象的集合 数据库的大多数操作是在这个类操作
 */
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

/**
 持久化存储协调器，主要负责协调上下文玉存储的区域的关系。
 */
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
/**
 托管对象模型，其中一个托管对象模型关联到一个模型文件，里面存储着数据库的数据结构。
 */
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;


+ (instancetype)sharedManager;
/**
 保存
 */
- (void)saveContext;

@end



