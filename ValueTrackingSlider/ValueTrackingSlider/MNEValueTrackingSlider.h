//
//  CustomSlider.h
//  Measures
//
//  Created by Michael Neuwert on 4/26/11.
//  Copyright 2011 Neuwert Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MNESliderValuePopupView;
@class MNEValueTrackingSlider;


@protocol MNEValueTrackingSliderDelegate <NSObject>

@optional

/**
 * Gives the delegate the posibility to change the value before assigning it to the control
 */
- (float)slider:(MNEValueTrackingSlider *)slider convertValue:(float)value;

- (NSString *)slider:(MNEValueTrackingSlider *)slider descriptionForValue:(float)value;

@end


@interface MNEValueTrackingSlider : UISlider {
    MNESliderValuePopupView *valuePopupView;
}

@property (nonatomic, readonly) CGRect thumbRect;
@property (nonatomic, unsafe_unretained) id<MNEValueTrackingSliderDelegate> delegate;

@end
