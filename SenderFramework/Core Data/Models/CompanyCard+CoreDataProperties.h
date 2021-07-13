//
//  CompanyCard+CoreDataProperties.h
//  
//
//  Created by Roman Serga on 13/2/17.
//
//

#import "CompanyCard+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CompanyCard (CoreDataProperties)

+ (NSFetchRequest<CompanyCard *> *)fetchRequest;

@property (nullable, nonatomic, retain) Dialog *company;

@end

NS_ASSUME_NONNULL_END
