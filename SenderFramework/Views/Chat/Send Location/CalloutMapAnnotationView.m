#import "CalloutMapAnnotationView.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation CalloutMapAnnotationView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setUp];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    CGRect viewFrame = CGRectMake(0.0f, 0.0f, 268.0f, 0.0f);
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, viewFrame.size.width, 52.0f)];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.contentView];
    
    UIImage * backgroundImage = [UIImage imageFromSenderFrameworkNamed:@"label_address"];
    UIImageView * backgroundImageView = [[UIImageView alloc]initWithImage:backgroundImage];
    [self.contentView addSubview:backgroundImageView];

    self.backgroundColor = [UIColor clearColor];
    UIImage * pinImage = [UIImage imageFromSenderFrameworkNamed:@"pin_icon"];
    UIImageView * pinImageView = [[UIImageView alloc]initWithImage:pinImage];
    CGRect pinImageViewFrame = pinImageView.frame;
    pinImageViewFrame.origin.x = self.contentView.frame.size.width/2 - pinImageViewFrame.size.width/2;
    pinImageViewFrame.origin.y = CGRectGetMaxY(self.contentView.frame);
    pinImageView.frame = pinImageViewFrame;
    [self addSubview:pinImageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.0f, -5.0f, 210.0f, 50.0f)];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview:self.titleLabel];
    
    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
    [self.actionButton setImage:[UIImage imageFromSenderFrameworkNamed:@"send_location"]
                       forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.actionButton];
    
    viewFrame.size.height = CGRectGetMaxY(pinImageViewFrame);
    self.frame = viewFrame;
}

- (void)buttonAction
{
    if ([self.delegate respondsToSelector:@selector(calloutMapAnnotationViewDidSelect:)])
        [self.delegate calloutMapAnnotationViewDidSelect:self];
}

- (void)updateWithAnnotation:(id<MWMapAnnotation>)annotation
{
    NSString * title;
    if ([annotation.title length])
    {
        title = annotation.title;
    }
    else
    {
        NSString * lat = [NSString stringWithFormat:@"%.6g", annotation.coordinate.latitude];
        NSString * lon = [NSString stringWithFormat:@"%.6g", annotation.coordinate.longitude];
        title = [NSString stringWithFormat:@"%@, %@", lat, lon];
    }
    NSArray * textArr = [title componentsSeparatedByString:@"\n"];
    self.titleLabel.text = textArr[0];
}

@end
