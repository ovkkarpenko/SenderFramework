//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerManagerOneCompany.h"
#import "EntityViewModel.h"


@implementation ChatPickerManagerOneCompany
{
    BOOL companyIsSelected;
}

- (void)selectCellModel:(id <EntityViewModel>)cellModel
{
    if (companyIsSelected && cellModel.chatType == ChatTypeCompany)
    {
        [self.displayController showOneCompanyAllowedError];
        return;
    }

    if (cellModel.chatType == ChatTypeCompany)
        companyIsSelected = YES;

    [super selectCellModel:cellModel];
}

- (void)deselectCellModel:(id <EntityViewModel>)cellModel
{
    if (self.allowsMultipleSelection)
        [self.selectedChatModels removeObject:cellModel];

    if (cellModel.chatType == ChatTypeCompany)
        companyIsSelected = NO;
}

@end