//
//  PBConsoleConstants.m
//  
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import "PBConsoleConstants.h"
#import "UIView+MWSubviews.h"
#import "UIImageView (UITextFieldBackground).h"
#import "MainContainerModel.h"

@implementation PBConsoleConstants

NSString * const PBAddSelectViewToScene = @"AddViewToScene";
NSString * const PBRemoveViewFromScene = @"RemoveViewFromScene";
NSString * const PBChatSendValueNotification = @"ConsoleSendCommand";
NSString * const PBChatLoseFocus = @"ConsoleLoseFocus";
bool change;

#pragma mark FONTS

+ (UIFont *)headerFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:IS_IPAD ? 18.0f : 16.0f];
}

+ (UIFont *)titleFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0];
}

+ (UIFont *)inputTextFieldFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:15.0];
}

+ (UIFont *)inputTextFieldFontStyle:(NSString *)style andSize:(float)size
{
    NSString * fontName = @"HelveticaNeue";
    
    if (style) {
        fontName = [fontName stringByAppendingString:style];
    }
    if (!size) {
        size = 15.0;
    }
    
    return [UIFont fontWithName:fontName size:size];
}

+ (UIFont *)placeholderTextFieldFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:15.0];
}

+ (UIFont *)timeMarkerFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
}

+ (UIFont *)dateMarkerFont
{
    return [UIFont fontWithName:@"HelveticaNeue" size:13.0];
}

#pragma mark COLORS

+ (UIColor *)colorWithHexString:(NSString *)str
{
    const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
    if (cStr == NULL) return nil;
    long x = strtol(cStr+1, NULL, 16);
    return [self colorWithHex:(UInt32)x];
}

+ (UIColor *)colorWithHex:(UInt32)col
{
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

+ (UIColor *)colorDeepBlue
{
    return [UIColor colorWithRed:50/255.0 green:10/255.0 blue:100/255.0 alpha:1.0];
}

+ (UIColor *)colorBorderGrey
{
    return [UIColor colorWithRed:195/255.0 green:195/255.0 blue:210/255.0 alpha:1.0];
}

+ (UIColor *)colorGrey
{
    return [UIColor colorWithRed:110/255.0 green:110/255.0 blue:130/255.0 alpha:1.0];
}

+ (UIColor *)colorGreenSelected
{
    return [self colorWithHexString:@"#179a83"];
}

+ (UIColor *)mainBlueColor
{
    return [self colorWithHexString:@"#7F80B0"];
}

+ (UIColor *)mainTextColor
{
    return [self colorWithHexString:@"#333333"];
}

+ (UIColor *)secondaryTextColor
{
    return [self colorWithHexString:@"#888888"];
}

+ (UIColor *)commonGreyColor
{
    return [self colorWithHexString:@"#6C6B6F"];
}

#pragma mark MATH FUNCTIONS

CGSize CalculateSenderHeaderSize (NSString * text, UIFont * font, float cellWidth)
{
    if ([text isKindOfClass:[NSNull class]] || text.length <= 0){
        CGSize size;
        
        size.width = 0;
        size.height = 0;
        return  size;
    }
    NSDictionary * attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                                          nil];
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(cellWidth, 1000)
                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                  attributes:attributesDictionary
                                     context:nil].size;
    if (text.length <= 0) {
        size.height = 0;
        return size;
    }
    
    return size;
}

+ (BOOL)checkPhoneField:(UITextField *)textField range:(NSRange)range replacementString:(NSString *)string
{
    if (range.length && [string isEqualToString:@""]) {
        return true;
    }
    
    NSString * strRezult = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ([strRezult isEqualToString:@"+"] || strRezult.length == 0) {
        return true;
    }
    else if (strRezult.length == 1) {
        int ch = (int)[strRezult characterAtIndex:0];
        
        if (ch >= 48 && ch <= 57) {
            strRezult = [NSString stringWithFormat:@"+%@",strRezult];
            textField.text = @"+";
            return true;
        }
    }
    
    if (![self isNumericINTEGER:[strRezult substringFromIndex:1]]) {
        return NO;
    }
    
    NSString *strippedNumber = [strRezult stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [strRezult length])];
    
    if(strRezult.length > 1 && [strippedNumber integerValue] > 0 && [[strRezult substringToIndex:1] isEqualToString:@"+"] ) {
        return true;
    }
    
    return false;
}

+ (BOOL)isNumericINTEGER:(NSString *) testString
{
    NSString *strippedNumber = [testString stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [testString length])];
    
    if ([strippedNumber length] == 0){
        return false;
    }
    if (strippedNumber.length == testString.length){
        return true;
    }
    else if([strippedNumber length] == 0 && testString.length > 0){
        return false;
    }
    else if([strippedNumber length] < testString.length){
        return false;
    }
    return true;
}

+ (BOOL)isNumericI:(NSString *) testString
{
    NSString *strippedNumber = [testString stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [testString length])];
    
    if ([testString rangeOfString:@"."].location != NSNotFound && [strippedNumber length] == 0){
        return false;
    }
    if (strippedNumber.length == testString.length){
        return true;
    }
    if ([testString rangeOfString:@"."].location != NSNotFound && strippedNumber.length +1 == testString.length){
        return true;
    }
    else if([strippedNumber length] == 0 && testString.length > 0){
        return false;
    }
    else if([strippedNumber length] < testString.length){
        return false;
    }
    return true;
}

+ (BOOL)checkFloat:(NSString *)string
{
    NSUInteger numberOfMatches = 0;
    if (string.length) {
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+[.][0-9]{2}"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        numberOfMatches = [regex numberOfMatchesInString:string
                                                 options:0
                                                   range:NSMakeRange(0, [string length])];
    }
    
    return numberOfMatches == 1;
}

BOOL ValidateEmail(NSString * emailForTest)
{
    NSString *emailSymb = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailRes = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailSymb];
    
    return [emailRes evaluateWithObject:emailForTest];
}

#pragma mark GRAPH FUNCTIONS

+ (void)makeTextFieldUnselected:(UITextField *)textField
{
    [self assingTextFieldParams:textField];
    textField.layer.borderColor = [self colorBorderGrey].CGColor;
    textField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
}

+ (void)makeTextFieldSelected:(UITextField *)textField
{
    [self assingTextFieldParams:textField];
    textField.layer.borderColor = [self mainBlueColor].CGColor;
    textField.backgroundColor = [UIColor whiteColor];
}

+ (void)assingTextFieldParams:(UITextField *)textField
{
    textField.borderStyle = UITextBorderStyleLine;
    
    textField.layer.cornerRadius = 0.0f;
    textField.layer.borderWidth = 1.0f;
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0, 10.0)];
    [textField setLeftViewMode:UITextFieldViewModeAlways];
    [textField setLeftView:spacerView];
}

+ (void)postString
{
    NSString * string = @".";
	UIView * responderView = [UIView mw_findFirstResponder];
	if (responderView == nil) return;
	
	id<UITextInput> textInput = [self findViewsSubviewWithTextInput:responderView];
	if (textInput == nil) return;
	
	// По какой-то причине не срабатывают делегаты при таком постинге.
	// Обработаю особым образом UITextField.
	if ([responderView isKindOfClass:[UITextField class]])
    {
		UITextField *inputField = (UITextField*)responderView;
		UITextRange *selRange = [textInput selectedTextRange];
		id<UITextFieldDelegate> delegate = [inputField delegate];
		NSRange range = [self makeSimpleRangeFromTextRange:selRange forTextInput:textInput];
		if ([delegate textField:inputField shouldChangeCharactersInRange:range replacementString:string]) {
			
            [textInput replaceRange:selRange withText:string];
			
		}
	} else {
        
        UITextRange *selectedRange = [textInput selectedTextRange];
        [textInput replaceRange:selectedRange withText:string];
	}
}

+ (id) findViewsSubviewWithTextInput:(UIView*)item
{
	if ([item conformsToProtocol:@protocol(UITextInput)]) return item;
	
	for (UIView * v in [item subviews]) {
		id res = [self findViewsSubviewWithTextInput:v];
		if (res) return res;
	}
	return nil;
}

+ (NSRange) makeSimpleRangeFromTextRange:(UITextRange*)textRange forTextInput:(id<UITextInput>)input
{
	NSUInteger length = [input offsetFromPosition:textRange.start toPosition:textRange.end];
	NSUInteger location = [input offsetFromPosition:input.beginningOfDocument toPosition:textRange.start];
	return NSMakeRange(location, length);
}

+ (void)imageSetRounds:(UIImageView *)imgView;
{
    imgView.layer.cornerRadius = imgView.frame.size.height/2;
    imgView.clipsToBounds = YES;
}

+ (UIImage *)maskImageWithCustomImage:(UIImage *)image maskImage:(UIImage *)maskImage
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    
    CGImageRef maskImageRef = [maskImage CGImage];

    CGContextRef mainViewContentContext = CGBitmapContextCreate(NULL, maskImage.size.width, maskImage.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    
    if (mainViewContentContext==NULL)
        return NULL;
    
    CGFloat ratio = 0;
    
    ratio = maskImage.size.width/ image.size.width;
    
    if(ratio * image.size.height < maskImage.size.height) {
        ratio = maskImage.size.height/ image.size.height;
    }
    
    CGRect rect1  = {{0, 0}, {maskImage.size.width, maskImage.size.height}};
    CGRect rect2  = {{-((image.size.width*ratio)-maskImage.size.width)/2 , -((image.size.height*ratio)-maskImage.size.height)/2}, {image.size.width*ratio, image.size.height*ratio}};
    
    CGContextClipToMask(mainViewContentContext, rect1, maskImageRef);
    CGContextDrawImage(mainViewContentContext, rect2, image.CGImage);
    
    CGImageRef newImage = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    
    UIImage * theImage = [UIImage imageWithCGImage:newImage];
    
    CGImageRelease(newImage);

    return theImage;
}

+ (void)settingViewBorder:(UIView *)operandView andModel:(MainContainerModel *)viewModel
{
        if (viewModel.b_size) {
        operandView.layer.borderWidth = [viewModel.b_size floatValue];
        }
        if (viewModel.b_color) {
            operandView.layer.borderColor = [self colorWithHexString:viewModel.b_color].CGColor;
        }
        
        if (viewModel.b_radius) {
            
            operandView.layer.cornerRadius = [viewModel.b_radius floatValue];
            operandView.clipsToBounds = YES;
        }
}

- (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)renderViewToImage:(UIView *)view
{
    UIGraphicsBeginImageContext(view.frame.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)downloadFromBundle:(NSString *)name ext:(NSString *)ext
{
    NSString * filePath = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if(filePath == nil)
    {
        NSString * filename = [NSString stringWithFormat:@"%@@2x", name];
        filePath = [SENDER_FRAMEWORK_BUNDLE pathForResource:filename ofType:ext];
    }
    
    return [UIImage imageWithContentsOfFile:filePath];
}

+ (void)setButtonSelected:(UIButton *)button
{
    UIImage * image = button.imageView.image;
    //set Main tint
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    [[PBConsoleConstants colorGreenSelected] setFill];
    CGContextFillRect(context, rect);
    UIImage * newImageMain = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [button setImage:newImageMain forState:UIControlStateNormal];
}

+ (void)setButtonDefault:(UIButton *)button
{
    UIImage * image = button.imageView.image;
    //set Main tint
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    [[PBConsoleConstants mainBlueColor] setFill];
    CGContextFillRect(context, rect);
    UIImage * newImageMain = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [button setImage:newImageMain forState:UIControlStateNormal];
    
    //set Push tint
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    [[PBConsoleConstants colorBorderGrey] setFill];
    CGContextFillRect(context, rect);
    UIImage * newImageHightLight = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [button setImage:newImageHightLight forState:UIControlStateHighlighted];
}

+ (void)setSystemButton:(UIButton *)button withText:(NSString *)title orImage:(NSString *)imageName
{
    if (imageName) {
        
        UIImage * image = [UIImage imageFromSenderFrameworkNamed:imageName];
        //set Main tint
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        CGContextClipToMask(context, rect, image.CGImage);
        [[PBConsoleConstants mainBlueColor] setFill];
        CGContextFillRect(context, rect);
        UIImage * newImageMain = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [button setImage:newImageMain forState:UIControlStateNormal];
        
        //set Push tint
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        rect = CGRectMake(0, 0, image.size.width, image.size.height);
        CGContextClipToMask(context, rect, image.CGImage);
        [[PBConsoleConstants colorBorderGrey] setFill];
        CGContextFillRect(context, rect);
        UIImage * newImageHightLight = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [button setImage:newImageHightLight forState:UIControlStateHighlighted];
        
    }
    
    if (title) {
        [button setTitle:title forState:UIControlStateNormal || UIControlStateHighlighted];
        
        [button setTitleColor:[PBConsoleConstants mainBlueColor] forState:UIControlStateNormal];
        [button setTitleColor:[PBConsoleConstants colorBorderGrey] forState:UIControlStateHighlighted];
    }
}

+ (void)setCustomSystemButton:(UIButton *)button withText:(NSString *)title orImage:(NSString *)imageName color:(UIColor *)color
{
    if (imageName) {
        
        UIImage * image = [UIImage imageFromSenderFrameworkNamed:imageName];
        //set Main tint
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        CGContextClipToMask(context, rect, image.CGImage);
        [color setFill];
        CGContextFillRect(context, rect);
        UIImage * newImageMain = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [button setImage:newImageMain forState:UIControlStateNormal];
        
        //set Push tint
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        rect = CGRectMake(0, 0, image.size.width, image.size.height);
        CGContextClipToMask(context, rect, image.CGImage);
        [[PBConsoleConstants colorBorderGrey] setFill];
        CGContextFillRect(context, rect);
        UIImage * newImageHightLight = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [button setImage:newImageHightLight forState:UIControlStateHighlighted];
        
    }
    
    if (title) {
        [button setTitle:title forState:UIControlStateNormal || UIControlStateHighlighted];
        
        [button setTitleColor:color forState:UIControlStateNormal];
        [button setTitleColor:[PBConsoleConstants colorBorderGrey] forState:UIControlStateHighlighted];
    }
}

+ (void)changePlaceholderIn:(UITextField *)textField toColor:(UIColor *)color
{
    CGRect rect = textField.frame;
    NSDictionary * attributes = @{NSForegroundColorAttributeName: color, NSFontAttributeName: textField.font};
    CGRect boundingRect = [textField.placeholder boundingRectWithSize:rect.size options:0 attributes:attributes context:nil];
    [textField.placeholder drawAtPoint:CGPointMake(0, (rect.size.height/2)-boundingRect.size.height/2) withAttributes:attributes];
}

@end
