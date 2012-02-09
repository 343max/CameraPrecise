//
//  CameraPrecise.m
//  SnapShocked
//
//  Created by Max Winde on 20.11.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraPrecise.h"

@implementation CameraPrecise
@synthesize session, image, snapShots;
static CameraPrecise *sharedInstance = nil;

- (void) initialize:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
	NSUInteger argc = [arguments count];
	NSString* successCallback = nil;
    //NSString* errorCallback = nil;
	
	if (argc < 1) {
		NSLog(@"CameraPrecise.initialize: Missing 1st parameter deviceNum");
		return;
	}
	
	if (argc > 1) successCallback = [arguments objectAtIndex:1];
	//if (argc > 2) errorCallback = [arguments objectAtIndex:2];
	
	
	int captureDeviceIndex = 0;
	NSString* captureDeviceIndexString = [arguments objectAtIndex:0];
	if (captureDeviceIndexString != nil) {
		captureDeviceIndex = [captureDeviceIndexString intValue];
	}
		
#if TARGET_IPHONE_SIMULATOR
	//
#else
	NSString* avCaptureSessionPresetString = [options objectForKey:@"preset"];
	NSString* avCaptureSessionPreset = AVCaptureSessionPresetLow;
	
	if(avCaptureSessionPresetString != nil) {
		if([avCaptureSessionPresetString compare:@"high" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			avCaptureSessionPreset = AVCaptureSessionPresetHigh;
		}
		
		if([avCaptureSessionPresetString compare:@"medium" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			avCaptureSessionPreset = AVCaptureSessionPresetMedium;
		}
		
		if([avCaptureSessionPresetString compare:@"low" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			avCaptureSessionPreset = AVCaptureSessionPresetLow;
		}
		
		if([avCaptureSessionPresetString compare:@"640x480" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			avCaptureSessionPreset = AVCaptureSessionPreset640x480;
		}
		
		if([avCaptureSessionPresetString compare:@"1280x720" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			avCaptureSessionPreset = AVCaptureSessionPreset1280x720;
		}
	}
	
	NSLog(@"%@", avCaptureSessionPresetString);
	NSLog(@"%@", avCaptureSessionPreset);
	
	NSError *error = nil;
	NSArray *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	AVCaptureDevice *captureDevice = [captureDevices objectAtIndex:captureDeviceIndex];
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
	if (!captureInput)
	{
		NSLog(@"Error: %@", error);
		return;
	}
	
	// Update thanks to Jake Marsh who points out not to use the main queue
	dispatch_queue_t queue = dispatch_queue_create("com.myapp.tasks.grabcameraframes", NULL);
	AVCaptureVideoDataOutput *captureOutput = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
	captureOutput.alwaysDiscardsLateVideoFrames = YES; 
	[captureOutput setSampleBufferDelegate:self queue:queue];
	// dispatch_release(queue); // Will not work when uncommented -- apparently reference count is altered by setSampleBufferDelegate:queue:
	
	NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
	[captureOutput setVideoSettings:videoSettings];
	
	
	self.session = [[[AVCaptureSession alloc] init] autorelease];
	self.session.sessionPreset = avCaptureSessionPreset;
	[self.session addInput:captureInput];
	[self.session addOutput:captureOutput];
	
	[self.session startRunning];
#endif
	
	self.snapShots = [NSMutableArray arrayWithCapacity:0];
	
	if (successCallback) {
		NSString* jsString = [NSString stringWithFormat:@"%@();", successCallback];
		[webView stringByEvaluatingJavaScriptFromString:jsString];
	}
}

//#if TARGET_IPHONE_SIMULATOR
	//
//#else
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    CVPixelBufferLockBaseAddress(imageBuffer,0); 
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    CGImageRef newImage = CGBitmapContextCreateImage(context); 
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
	self.image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
	
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);
	CGImageRelease(newImage);
	[pool drain];
}
//#endif

- (void) snap:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
	NSUInteger argc = [arguments count];
	if(argc < 1) {
		NSLog(@"Missing params: sucessCallback");
		return;
	}	
	NSString* successCallback = nil;
	successCallback = [arguments objectAtIndex:0];

#if TARGET_IPHONE_SIMULATOR
	NSString* dummyImagePath = [NSString stringWithFormat:@"%@/www/i/dummy.png", [[NSBundle mainBundle] bundlePath]];
	[[self snapShots] addObject:[UIImage imageWithContentsOfFile:dummyImagePath]];
#else
	[[self snapShots] addObject:[self image]];
#endif
	
	NSString* jsString = [NSString stringWithFormat:@"%@();", successCallback];
	[webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void) getSnapShot:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
	NSUInteger argc = [arguments count];
	if(argc < 2) {
		NSLog(@"Missing params: index, sucessCallback");
		return;
	}
	
	NSInteger index = [[arguments objectAtIndex:0] integerValue];
	
	NSString* successCallback = nil;
	successCallback = [arguments objectAtIndex:1];
	
	CGFloat quality = 1.0;
	if (argc >= 2) {
		NSInteger qualityInt = [[arguments objectAtIndex:2] integerValue];
		quality = (double)qualityInt / 100.0;
	}
	
	if (index < 0) {
		NSLog(@"Out of bounds: index can't be < 0");
		return;
	}
	
	if (index >= [[self snapShots] count]) {
		NSLog(@"Out of bounds: index to big");
		return;
	}
		
	UIImage* snapShot = [[self snapShots] objectAtIndex:index];

	NSLog(@"Quality: %.2f", quality);
	NSData* data = UIImageJPEGRepresentation(snapShot, quality);
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\");", successCallback, [data base64EncodedString]];
	[webView stringByEvaluatingJavaScriptFromString:jsString];	
}

- (void) countSnapShots:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
	NSString* successCallback = nil;
	NSUInteger argc = [arguments count];
	
	if(argc < 1) {
		NSLog(@"Missing first parameter: successCalback");
		return;
	}
	successCallback = [arguments objectAtIndex:0];
	
	NSString* jsString = [NSString stringWithFormat:@"%@(%@);", successCallback, [NSNumber numberWithInt:[[self snapShots] count]]];
	[webView stringByEvaluatingJavaScriptFromString:jsString];
}


#pragma mark Class Interface

+ (id) sharedInstance // private
{
	if(!sharedInstance) sharedInstance = [[self alloc] init];
    return sharedInstance;
}

+ (void) startRunning
{
	[[[self sharedInstance] session] startRunning];	
}

+ (void) stopRunning
{
	[[[self sharedInstance] session] stopRunning];
}

+ (UIImage *) image
{
	return [[self sharedInstance] image];
}

+ (NSMutableArray *) snapShots
{
	return [[self sharedInstance] snapShots];
}

@end
