//
//  CameraPrecise.h
//  SnapShocked
//
//  Created by Max Winde on 20.11.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "PhoneGapCommand.h"

#if TARGET_IPHONE_SIMULATOR

@interface CameraPrecise : PhoneGapCommand
{
	UIImage *image;
	NSObject *session;
	NSMutableArray *snapShots;
}

@property (retain) UIImage *image;
@property (retain) NSObject *session;
@property (retain) NSMutableArray *snapShots;

#else

@interface CameraPrecise : PhoneGapCommand <AVCaptureVideoDataOutputSampleBufferDelegate>
{
	UIImage *image;
	AVCaptureSession *session;
	NSMutableArray *snapShots;
}

@property (retain) UIImage *image;
@property (retain) AVCaptureSession *session;
@property (retain) NSMutableArray *snapShots;

#endif

- (void) initialize:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) snap:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) getSnapShot:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) countSnapShots:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

+ (UIImage *) image;

@end
