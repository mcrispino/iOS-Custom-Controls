//
//  CustomSlider.m
//  Measures
//
//  Created by Michael Neuwert on 4/26/11.
//  Copyright 2011 Neuwert Media. All rights reserved.
//

#import "MNEValueTrackingSlider.h"

#pragma mark - Private UIView subclass rendering the popup showing slider value

@interface MNESliderValuePopupView : UIView  
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *foreColor;
@property (nonatomic, strong) UIColor *fillColor;
@end

@implementation MNESliderValuePopupView

@synthesize font=_font;
@synthesize text = _text;
@synthesize foreColor = _foreColor;
@synthesize fillColor = _fillColor;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont boldSystemFontOfSize:18];
		self.foreColor = [UIColor colorWithWhite:1 alpha:0.8];
		self.fillColor = [UIColor colorWithWhite:0 alpha:0.8];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // Set the fill color
	[self.fillColor setFill];

    // Create the path for the rounded rectangle
    CGRect roundedRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, floorf(self.bounds.size.height * 0.8));
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:6.0];
    
    // Create the arrow path
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    CGFloat midX = CGRectGetMidX(self.bounds);
    CGPoint p0 = CGPointMake(midX, CGRectGetMaxY(self.bounds));
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((midX - 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((midX + 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];
    
    // Attach the arrow path to the rounded rect
    [roundedRectPath appendPath:arrowPath];

    [roundedRectPath fill];

    // Draw the text
    if (self.text) {
        [self.foreColor set];
        CGSize s = [_text sizeWithFont:self.font];
        CGFloat yOffset = (roundedRect.size.height - s.height) / 2;
        CGRect textRect = CGRectMake(roundedRect.origin.x, yOffset, roundedRect.size.width, s.height);
        
        [_text drawInRect:textRect 
                 withFont:self.font 
            lineBreakMode:UILineBreakModeWordWrap 
                alignment:UITextAlignmentCenter];    
    }
}

- (void)setText:(NSString *)text {
	_text = text;
	[self setNeedsDisplay];
}

@end

#pragma mark - MNEValueTrackingSlider implementations

@implementation MNEValueTrackingSlider {
	BOOL _trackingMove;
}

@synthesize thumbRect;
@synthesize delegate;

#pragma mark - Private methods

- (void)constructSlider {
    valuePopupView = [[MNESliderValuePopupView alloc] initWithFrame:CGRectZero];
    valuePopupView.backgroundColor = [UIColor clearColor];
    valuePopupView.alpha = 0.0;
    [self addSubview:valuePopupView];
}

- (void)fadePopupViewInAndOut:(BOOL)aFadeIn {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    if (aFadeIn) {
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadePopupViewOut) object:nil];
        valuePopupView.alpha = 1.0;
    } else {
        valuePopupView.alpha = 0.0;
    }
    [UIView commitAnimations];
}

- (void)fadePopupViewIn {
	[self fadePopupViewInAndOut:YES];
}

- (void)fadePopupViewOut {
	[self fadePopupViewInAndOut:NO];
}

- (void)fadePopupViewOutAfterDelay {
	[self performSelector:@selector(fadePopupViewOut) withObject:nil afterDelay:(NSTimeInterval)2.0];
}

- (void)positionAndUpdatePopupView {
    CGRect _thumbRect = self.thumbRect;
    CGRect popupRect = CGRectOffset(_thumbRect, 0, -floorf(_thumbRect.size.height * 1.5));
    valuePopupView.frame = CGRectInset(popupRect, -16, -8);
	
	float value = self.value;
	if ([self.delegate respondsToSelector:@selector(slider:convertValue:)]) {
		value = [self.delegate slider:self convertValue:value];
	}
	
	if ([self.delegate respondsToSelector:@selector(slider:descriptionForValue:)]) {
		valuePopupView.text = [self.delegate slider:self descriptionForValue:value];
	}
	else {
		valuePopupView.text = [NSString stringWithFormat:@"%4.2f", value];
	}
}

#pragma mark - Memory management

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self constructSlider];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self constructSlider];
    }
    return self;
}

#pragma mark - UIControl touch event tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade in and update the popup view
	_trackingMove = NO;
    CGPoint touchPoint = [touch locationInView:self];
    // Check if the knob is touched. Only in this case show the popup-view
    if(CGRectContainsPoint(CGRectInset(self.thumbRect, -12.0, -12.0), touchPoint)) {
        [self positionAndUpdatePopupView];
        [self fadePopupViewIn];
    }
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Update the popup view as slider knob is being moved
	_trackingMove = YES;
    [self positionAndUpdatePopupView];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
	[self fadePopupViewOut];
	_trackingMove = NO;
	[super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // Fade out the popoup view
	if (_trackingMove)
		[self fadePopupViewOut];
	else
		[self fadePopupViewOutAfterDelay];
	_trackingMove = NO;
    [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark - Custom property accessors

- (CGRect)thumbRect {
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbR = [self thumbRectForBounds:self.bounds 
                                         trackRect:trackRect
                                             value:self.value];
    return thumbR;
}

@end
