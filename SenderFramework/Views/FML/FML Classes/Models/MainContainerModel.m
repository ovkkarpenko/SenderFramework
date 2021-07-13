//
//  MainContainerModel.m
//  SENDER
//
//  Created by Eugene on 10/16/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MainContainerModel.h"
#import "ParamsFacade.h"
#import "Item.h"
#import "SenderNotifications.h"
#import "ServerFacade.h"
#import "BitcoinUtils.h"
#import <ObjectiveLuhn/Luhn.h>

@implementation MainContainerModel
@synthesize type,
            name,
            bg,
            val,
            hint,
            w,
            h,
            weight,
            src,
            action,
            actions,
            pd,
            mg,
            items,
            state,
            size,
            color,
            tstyle,
            it,
            vars,
            vars_type,
            fontStyle,
            fontSize,
            totalWeight,
            topTotalWeight,
            title,
            b_size,
            b_color,
            b_radius,
            bottomPadding,
            talign,
            valign,
            halign,
            regexp,
            regexpText,
			modelRegExp,
            required;


- (MainContainerModel *)initWithMessageData:(Message *)model
{
    self = [super init];
    if (self)
    {
        self.data = model.data;
        NSDictionary * dData = [[ParamsFacade sharedInstance] dictionaryFromNSData:model.data];
        if (model.procId) self.procId = model.procId;
        self = [self addNewModelInSubModels:dData parentModel:nil chat:[model fmlDialog]];
    }
    
    return self;
}

- (void)updateView
{
    [self.view updateView];
}

- (MainContainerModel *)addNewModelInSubModels:(NSDictionary *)data
                                   parentModel:(MainContainerModel *)parent
                                          chat:(Dialog *)chat
{
    MainContainerModel * itemModel = [[MainContainerModel alloc] init];

    itemModel.chat = chat;

    if (self.procId) {
        itemModel.procId = self.procId;
    }
    else if (data[@"procId"]){
        itemModel.procId = data[@"procId"];
    }
    
    if (parent) {
        itemModel.topModel = parent;
    }
    
    itemModel.type = data[@"type"];
    itemModel.className = [self classNameFromType:itemModel.type];
    
    if (parent.size && !data[@"size"]) {
        itemModel.size = parent.size;
    }
    else {
        itemModel.size = data[@"size"];
    }
    
    if (parent.color && !data[@"color"]) {
        itemModel.color = parent.color;
    }
    else {
        itemModel.color = data[@"color"];
    }
    
    if (parent.tstyle && !data[@"tstyle"]) {
        itemModel.tstyle = parent.tstyle;
    }
    else {
        itemModel.tstyle = data[@"tstyle"];
    }
    
    if (parent.talign && !data[@"talign"]) {
        itemModel.talign = parent.talign;
    }
    else {
        itemModel.talign = data[@"talign"];
    }

    itemModel.bottomPadding = 0;
    
    if (data[@"pd"]) {
        if ([itemModel.type isEqualToString:@"text"]) {
            
        }
        itemModel.pd = data[@"pd"];
        
        itemModel.bottomPadding += (int)[itemModel.pd[2] integerValue];
    }
    
    if (data[@"mg"]) {
        itemModel.mg = data[@"mg"];
        itemModel.bottomPadding += (int)[itemModel.mg[2] integerValue];
    }
    
    itemModel.name = data[@"name"];
    itemModel.bg = data[@"bg"];
    itemModel.val = data[@"val"];
    itemModel.hint = data[@"hint"];
    
    if (data[@"w"]) {
        itemModel.w = [NSNumber numberWithInteger:[data[@"w"] integerValue]];
    }
    else {
        itemModel.weight = (data[@"weight"]) ? data[@"weight"] : @"1";
    }
    
    if (data[@"h"]) {
        itemModel.h = [NSNumber numberWithInteger:[data[@"h"] integerValue]];
    }

    itemModel.src = data[@"src"];
    if (data[@"action"]) itemModel.action = data[@"action"];
    if (data[@"actions"]) itemModel.actions = data[@"actions"];
    
    if (data[@"items"])
        itemModel.items = data[@"items"];
    
    if (data[@"state"] && ((NSString *)data[@"state"]).length > 0) {
        itemModel.state = data[@"state"];
    }
    else {
        
        itemModel.state = @"enable";
    }
    
    itemModel.vars = data[@"vars"];
    itemModel.vars_type = data[@"vars_type"];
    itemModel.it = data[@"it"];
    itemModel.title = data[@"title"];
    itemModel.b_size = data[@"b_size"];
    itemModel.b_color = data[@"b_color"];
    itemModel.b_radius = data[@"b_radius"];

    if (data[@"valign"]) {
        itemModel.valign = data[@"valign"];
    }

    if (data[@"halign"]) {
        itemModel.halign = data[@"halign"];
    }

    itemModel.regexp = data[@"regexp"];
    itemModel.regexpText = data[@"regexpText"];
    itemModel.required = [data[@"required"] boolValue];

    if (itemModel.items.count) {
        itemModel.submodels = [self submodelsInModel:itemModel.items parentModel:itemModel];//parent ? parent:itemModel];
    }
    
    return itemModel;
}

- (NSArray *)submodelsInModel:(NSArray *)sItems parentModel:(MainContainerModel *)parent
{
    NSMutableArray * sub = [[NSMutableArray alloc] init];
    
    for (NSDictionary * item in sItems) {
        MainContainerModel * submodel = [self addNewModelInSubModels:item parentModel:parent chat:parent.chat];
        [sub addObject:submodel];
    }
    
    return [sub copy];
}

- (NSString *)classNameFromType:(NSString *)cType
{
    if ([cType isEqualToString:@"row"] || [cType isEqualToString:@"col"]) {
        return @"ColVewContainer";
    }
    else if ([cType isEqualToString:@"text"]) {
        return @"PBLabelView";
    }
    else if ([cType isEqualToString:@"edit"]) {
        return @"PBInputTextView";
    }
    else if ([cType isEqualToString:@"img"]) {
        return @"PBImageView";
    }
    else if ([cType isEqualToString:@"check"]) {
        return @"PBCheckBoxSelectView";
    }
    else if ([cType isEqualToString:@"radio"]) {
        return @"PBRadioSelectView";
    }
    else if ([cType isEqualToString:@"select"]) {
        return @"PBSelectedView";
    }
    else if ([cType isEqualToString:@"button"]) {
        return @"PBButtonInFormView";
    }
    else if ([cType isEqualToString:@"web"]) {
        return @"PBWebInFormView";
    }
    else if ([cType isEqualToString:@"map"]) {
        return @"PBMapView";
    }
    else if ([cType isEqualToString:@"tarea"]) {
        return @"PBTextAreaView";
    }
    else if ([cType isEqualToString:@"file"]) {
        return @"PBLoadFileView";
    }
    return @"ColVewContainer";
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.type forKey:@"type"];
}

- (id)initWithCoder:(NSCoder *)coder {
   
    self = [[MainContainerModel alloc] init];
    self.type = [coder decodeObjectForKey:@"type"];
    
    return self;
}

- (NSString *)fontStyle
{
    if (self.tstyle) {
        
        NSString * style = [self.tstyle firstObject];
        
        if ([style isEqualToString:@"bold"])
            return @"-Bold";
        else if ([style isEqualToString:@"italic"])
            return @"-Italic";
        else if ([style isEqualToString:@"underline"])
            return nil;
    }
    
    return nil;
}

- (float)fontSize
{
    return [self.size floatValue];
}

- (NSDictionary *)getDataFromModel
{
    self.resultArray = [[NSMutableArray alloc] init];
    
    NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
    
    NSArray * dataArray = (self.topModel && self.topModel.submodels) ? self.topModel.submodels:self.submodels;
    
    @autoreleasepool {
    
        for (MainContainerModel * model in dataArray) {
            
            if (model.name) {
                [self.resultArray addObject:model];
            }
            
            if (model.submodels) {
                
                [self getSubModelFromModel:model];
            }
        }
        
        for (MainContainerModel * finModel in  self.resultArray) {
            if (finModel.name) {
                
                if (finModel.val && finModel.name) {

                    NSError * error;
                    if ( ![self validateModel:finModel error:&error] )
                	    return @{@"error" : error};

                    if ([finModel.val isEqualToString:@"true"] || [finModel.val isEqualToString:@"false"]) {
                        [result setObject:[self stringToBool:finModel.val] forKey:finModel.name];
                    }
                    else {
                        [result setObject:finModel.val forKey:finModel.name];
                    }
                    
                    if (finModel.action) {
                        [self addKeysFrom:finModel.action to:result];
                    }
                    else if (finModel.actions) {
                        
                        for (NSDictionary * action_ in finModel.actions) {
                            if ([self addKeysFrom:action_ to:result]) {
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    return result;
}

- (id)stringToBool:(NSString *)val
{
    if ([val isEqualToString:@"true"]) {
        return [NSNumber numberWithBool:YES];
    }
    return [NSNumber numberWithBool:NO];
}

- (BOOL)validateModel:(MainContainerModel *)viewModel error:(NSError **)error
{
    BOOL isValid = YES;
    //TODO: regex implementation

    if ( viewModel.regexp.length )
    {
        BOOL isMatch = [self matchesEntirely:viewModel.regexp string:viewModel.it];

        if ( !isMatch )
        {
            NSString * errorText = SenderFrameworkLocalizedString( viewModel.regexpText, nil );

            if ( !errorText.length )
            {
                errorText = [NSString
                        stringWithFormat:
                                @"%@ «%@»",
                                SenderFrameworkLocalizedString(@"Неправильное значение поля", nil ),
                                SenderFrameworkLocalizedString( viewModel.title, nil )];
            }
            *error = [NSError errorWithDomain:errorText code:0 userInfo:nil];

            isValid = NO;
        }
    }

    if ( isValid )
    {
        if ( viewModel.required )
        {
            if ( !viewModel.val.length || [viewModel.val isEqualToString:@"0"] ||
                    [viewModel.val isEqualToString:@"false"] )
            {
                NSString * errorText = SenderFrameworkLocalizedString( viewModel.regexpText, nil );

                if ( !errorText.length )
                {
                    errorText = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"KM_EnterFieldAt",nil),
                                    SenderFrameworkLocalizedString( viewModel.title, nil )];
                }
                if (error)
                    *error = [NSError errorWithDomain:errorText code:0 userInfo:nil];

                isValid = NO;
            }
        }
    }

    return isValid;
}

- (BOOL)validateModel:(MainContainerModel *)model
{
    return YES;

    if ([model.it isEqualToString:@"cardnumber"]) {
        return [Luhn validateString:model.it];
    }
    else if (![model.it isEqualToString:@"text"]) {
        return [self matchesEntirely:model.modelRegExp string:model.it];
    }

    return YES;
}

#pragma mark Validate REGEXP

- (BOOL)matchesEntirely:(NSString*)regex string:(NSString*)str
{
    if (!regex || [regex isEqualToString:@"NA"]) {
        return YES;
    }

    NSError *error = nil;
    NSRegularExpression *currentPattern = [self entireRegularExpressionWithPattern:regex options:0 error:&error];
    NSRange stringRange = NSMakeRange(0, str.length);
    NSTextCheckingResult *matchResult = [currentPattern firstMatchInString:str options:NSMatchingAnchored range:stringRange];

    if (matchResult != nil) {
        BOOL matchIsEntireString = NSEqualRanges(matchResult.range, stringRange);
        if (matchIsEntireString)
        {
            return YES;
        }
    }

    return NO;
}


- (void)getSubModelFromModel:(MainContainerModel *)smodel
{
    for (MainContainerModel * subModel in smodel.submodels) {
        
        if (![subModel.type isEqualToString:@"button"]) {
            
            if (subModel.name) {
                [self.resultArray addObject:subModel];
            }
            if (subModel.submodels) {
                
                [self getSubModelFromModel:subModel];
            }
        }
    }
}

- (BOOL)addKeysFrom:(NSDictionary *)actionData to:(NSMutableDictionary *)result
{
    if (actionData[@"data"]) {
        
        for (id key in actionData[@"data"]) {
            [result setObject:actionData[@"data"][key] forKey:key];
        }
    }
    return YES;
}

- (void)addUser:(Contact *)item forField:(NSString *)field
{
    Item * itemP = [item getSomeItem];
    
    if(itemP && [itemP.type isEqualToString:@"phone"]) {
        [self setValue:itemP.value forField:field];
        
        MainContainerModel * model = [self findModelWithName:field];
        if (model)
        {
            model.val = itemP.value;
            model.bitcoinAddress = item.bitcoinAddress;
            [model updateView];
        }
    }
}

- (void)setValue:(NSString *)value forField:(NSString *)fieldName
{
    MainContainerModel * fieldToChange = [self findModelWithName:fieldName];
    if (fieldToChange)
    {
        fieldToChange.val = value;
        [fieldToChange updateView];
    }
}

- (MainContainerModel *)findModelWithName:(NSString *)modelName
{
    MainContainerModel * superModel = [self findTopModel:self];
    return [self findModelWithName:superModel andName:modelName];
}

- (MainContainerModel *)findTopModel:(MainContainerModel *)model;
{
    if ([model.topModel.submodels count]) {
        return [self findTopModel:model.topModel];
    }
    else {
        return model;
    }
}

- (MainContainerModel *)findModelWithName:(MainContainerModel *)topModel andName:(NSString * )name
{
    if (![topModel.submodels count]) {
        if ([topModel.name isEqualToString:name])
            return topModel;
        else
            return nil;
    }
    else {
        for (MainContainerModel * submodel in topModel.submodels) {
            MainContainerModel * model = [self findModelWithName:submodel andName:name];
            if (model != nil)
                return model;
        }
    }
    return nil;
}

- (FML_Action)detectAction:(NSDictionary *)action_
{
    NSString * actionString = action_[@"oper"];
    
    if ([actionString isEqualToString:@"callPhone"])
        return CallPhone;
    
    if ([actionString isEqualToString:@"selectUser"])
        return SelectUser;
    
    if ([actionString isEqualToString:@"callRobotInP2PChat"] ||
        [actionString isEqualToString:@"callRobot"] ||
        [actionString isEqualToString:@"startP2PChat"])
        return RunRobots;
    
    if ([actionString isEqualToString:@"qrScan"])
        return QrScan;
    
    if ([actionString isEqualToString:@"scanQrTo"])
        return ScanQrTo;
    
    if ([actionString isEqualToString:@"goTo"])
        return GoToSomeWhere;
    
    if ([actionString isEqualToString:@"showAsQr"])
        return ShowAsQr;
    
    if ([actionString isEqualToString:@"viewLink"])
        return ViewLink;
    
    if ([actionString isEqualToString:@"sendBtc"])
        return SendBtc;

    if ([actionString isEqualToString:@"showBtcArhive"])
        return ShowBtcArchive;

    if ([actionString isEqualToString:@"showBtcNotas"])
        return ShowBtcNotarize;

    if ([actionString isEqualToString:@"share"])
        return Share;

    if ([actionString isEqualToString:@"copy"])
        return Copy;
    
    if ([actionString isEqualToString:@"submitOnChange"])
        return SubmitOnChange;
    
    if ([actionString isEqualToString:@"coords"])
        return Coords;
    
    if ([actionString isEqualToString:@"chooseFile"])
        return LoadFile;
    
    if ([actionString isEqualToString:@"reCryptKey"])
        return ReCryptKey;
    
    if ([actionString isEqualToString:@"setGoogleToken"])
        return SetGoogleToken;

    if ([actionString isEqualToString:@"fullVersion"])
        return ChangeFullVersion;

    return NONE;
}

#pragma mark Calculate W

- (BOOL)viewHavePadding
{
    return [self checkArraySumm:self.pd];
}

- (BOOL)viewHaveMargins
{
    return [self checkArraySumm:self.mg];
}

- (BOOL)checkArraySumm:(NSArray *)array
{
    if (array) {
        
        int checkSum = 0;
        
        for (NSString * cVal in array) {
            if ([cVal integerValue] > 0) {
                checkSum++;
            }
        }
        
        if (checkSum > 0) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark Calculate H

- (float)correctHeight
{
    float fH = (int)[self.h integerValue];
    fH -= ((int)[self.pd[0] integerValue] + (int)[self.pd[2] integerValue]);
    fH -= ((int)[self.mg[0] integerValue] + (int)[self.mg[2] integerValue]);

    return fH;
}

- (NSRegularExpression *)entireRegularExpressionWithPattern:(NSString *)regexPattern
                                                    options:(NSRegularExpressionOptions)options
                                                      error:(NSError **)error
{
    [stringCacheLock lock];
    
    @try {
        
        NSString * finalRegexString = regexPattern;
        if ([regexPattern rangeOfString:@"^"].location == NSNotFound) {
            finalRegexString = [NSString stringWithFormat:@"^(?:%@)$", regexPattern];
        }
        
        NSRegularExpression *  regex = [self regularExpressionWithPattern:finalRegexString options:0 error:error];
        
        return regex;
    }
    @finally {
        [stringCacheLock unlock];
    }
}

- (NSRegularExpression *)regularExpressionWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError **)error
{
    [lockPatternCache lock];
    
    @try {
        
        NSRegularExpression * regex = regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:error];
        
        return regex;
    }
    @finally {
        [lockPatternCache unlock];
    }
}

@end
