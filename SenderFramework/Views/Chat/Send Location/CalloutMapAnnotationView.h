#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CalloutMapAnnotationView;

@protocol CalloutMapAnnotationViewDelegate <NSObject>

- (void)calloutMapAnnotationViewDidSelect:(CalloutMapAnnotationView *)calloutMapAnnotationView;

@end

@protocol MWMapAnnotationView;
@protocol MWMapAnnotation;

@interface CalloutMapAnnotationView : UIView <MWMapAnnotationView>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton * actionButton;
@property (nonatomic, strong) UILabel * titleLabel;

@property (nonatomic, strong) id<MWMapAnnotation> annotation;
@property (nonatomic, assign) id<CalloutMapAnnotationViewDelegate> delegate;

@end
