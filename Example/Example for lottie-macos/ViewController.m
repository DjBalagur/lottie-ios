//
//  ViewController.m
//  Example for lottie-macos
//
//  Created by Oleksii Pavlovskyi on 2/2/17.
//  Copyright © 2017 Brandon Withrow. All rights reserved.
//

#import "ViewController.h"
#import <Lottie/Lottie.h>
#import "LAMainView.h"
#import "LottieFilesURL.h"
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureOutput.h>

@implementation ViewController
{
    CGDirectDisplayID           display;
    AVCaptureMovieFileOutput    *captureMovieFileOutput;
    NSMutableArray              *shadeWindows;
}

- (void)viewDidLoad {
  [super viewDidLoad];

    self.view.layer.backgroundColor = [NSColor colorNamed:@"CustomBackgroundColor"].CGColor;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
    {
        /* Specifies capture settings suitable for high quality video and audio output. */
        [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    display = CGMainDisplayID();
    self.captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:display];
    self.captureScreenInput.capturesMouseClicks = NO;
    self.captureScreenInput.capturesCursor = NO;
    if ([self.captureSession canAddInput:self.captureScreenInput])
    {
        [self.captureSession addInput:self.captureScreenInput];
    }
    
    NSWindow *window = [[[NSApplication sharedApplication] windows] lastObject];
    [self addDisplayInputToCaptureSession:display cropRect:NSRectToCGRect(window.frame)];
    
    captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [captureMovieFileOutput setDelegate:self];
    if ([self.captureSession canAddOutput:captureMovieFileOutput])
    {
        [self.captureSession addOutput:captureMovieFileOutput];
    }
    
    [self.captureSession startRunning];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"startRecord"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self startRecording:nil];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"stopRecord"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self stopRecording:nil];
                                                  }];
}

-(void)addDisplayInputToCaptureSession:(CGDirectDisplayID)newDisplay cropRect:(CGRect)cropRect
{
    /* Indicates the start of a set of configuration changes to be made atomically. */
    [self.captureSession beginConfiguration];
    
    /* Is this display the current capture input? */
    if ( newDisplay != display )
    {
        /* Display is not the current input, so remove it. */
        [self.captureSession removeInput:self.captureScreenInput];
        AVCaptureScreenInput *newScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:newDisplay];
        newScreenInput.capturesMouseClicks = NO;
        newScreenInput.capturesCursor = NO;
        
        self.captureScreenInput = newScreenInput;
        if ( [self.captureSession canAddInput:self.captureScreenInput] )
        {
            /* Add the new display capture input. */
            [self.captureSession addInput:self.captureScreenInput];
        }
        [self setMaximumScreenInputFramerate:[self maximumScreenInputFramerate]];
    }
    /* Set the bounding rectangle of the screen area to be captured, in pixels. */
    [self.captureScreenInput setCropRect:cropRect];
    
    /* Commits the configuration changes. */
    [self.captureSession commitConfiguration];
}

- (void)setMaximumScreenInputFramerate:(float)maximumFramerate
{
    CMTime minimumFrameDuration = CMTimeMake(1, (int32_t)maximumFramerate);
    /* Set the screen input's minimum frame duration. */
    [self.captureScreenInput setMinFrameDuration:minimumFrameDuration];
}

- (float)maximumScreenInputFramerate
{
    Float64 minimumVideoFrameInterval = CMTimeGetSeconds([self.captureScreenInput minFrameDuration]);
    return minimumVideoFrameInterval > 0.0f ? 1.0f/minimumVideoFrameInterval : 0.0;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error)
    {
        [self presentError:error];
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:outputFileURL];
}


- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput
{
    // We don't require frame accurate start when we start a recording. If we answer YES, the capture output
    // applies outputSettings immediately when the session starts previewing, resulting in higher CPU usage
    // and shorter battery life.
    return NO;
}

- (IBAction)startRecording:(id)sender
{
    NSLog(@"Minimum Frame Duration: %f, Crop Rect: %@, Scale Factor: %f, Capture Mouse Clicks: %@, Capture Mouse Cursor: %@, Remove Duplicate Frames: %@",
          CMTimeGetSeconds([self.captureScreenInput minFrameDuration]),
          NSStringFromRect(NSRectFromCGRect([self.captureScreenInput cropRect])),
          [self.captureScreenInput scaleFactor],
          [self.captureScreenInput capturesMouseClicks] ? @"Yes" : @"No",
          [self.captureScreenInput capturesCursor] ? @"Yes" : @"No",
          [self.captureScreenInput removesDuplicateFrames] ? @"Yes" : @"No");
    
    /* Create a recording file */
    char *screenRecordingFileName = strdup([[@"~/Desktop/AVScreenShackRecording_XXXXXX" stringByStandardizingPath] fileSystemRepresentation]);
    if (screenRecordingFileName)
    {
        int fileDescriptor = mkstemp(screenRecordingFileName);
        if (fileDescriptor != -1)
        {
            NSString *filenameStr = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:screenRecordingFileName length:strlen(screenRecordingFileName)];
            
            /* Starts recording to a given URL. */
            [captureMovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[filenameStr stringByAppendingPathExtension:@"mov"]] recordingDelegate:self];
        }
        
        remove(screenRecordingFileName);
        free(screenRecordingFileName);
    }
}

/* Called when the user presses the 'Stop' button to stop a recording. */
- (IBAction)stopRecording:(id)sender
{
    [captureMovieFileOutput stopRecording];
}

- (void)viewDidAppear {
  [super viewDidAppear];
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
}

- (IBAction)_sliderChanged:(NSSlider *)sender {
//  [(LAMainView *)self.view setAnimationProgress:sender.floatValue];
}

- (IBAction)_rewind:(id)sender {
//  [(LAMainView *)self.view rewindAnimation];
}

- (IBAction)_play:(id)sender {
  [(LAMainView *)self.view playAnimation];
}

- (IBAction)_loops:(id)sender {
//  [(LAMainView *)self.view toggleLoop];
}

- (void)paste:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSURL class], nil];
    
    if ([pasteboard canReadObjectForClasses:classes options:nil]) {
        NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:nil];
        
        if (copiedItems != nil) {
            NSURL *url = (NSURL *)[copiedItems firstObject];
            LottieFilesURL *lottieFile = [[LottieFilesURL alloc] initWithURL:url];
            
            if (lottieFile != nil) {
                [(LAMainView *)self.view openAnimationURL:lottieFile.jsonURL];
                self.view.window.title =  lottieFile.animationName;
            }
        }
    }
}


@end
