//
//  ViewController.h
//  Example for lottie-macos
//
//  Created by Oleksii Pavlovskyi on 2/2/17.
//  Copyright © 2017 Brandon Withrow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVCaptureOutput.h>

@class AVCaptureSession, AVCaptureScreenInput, AVCaptureMovieFileOutput;

@interface ViewController : NSViewController <AVCaptureFileOutputDelegate,AVCaptureFileOutputRecordingDelegate>

@property (strong) AVCaptureSession *captureSession;
@property (strong) AVCaptureScreenInput *captureScreenInput;

@end

