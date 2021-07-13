//
//  CompanyCard+CoreDataProperties.m
//  
//
//  Created by Roman Serga on 13/2/17.
//
//

#import "CompanyCard+CoreDataProperties.h"

@implementation CompanyCard (CoreDataProperties)

+ (NSFetchRequest<CompanyCard *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CompanyCard"];
}

@dynamic company;

@end
