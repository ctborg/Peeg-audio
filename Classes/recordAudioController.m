//
//  recordAudioController.m
//  peeg
//

#import "recordAudioController.h"

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

@implementation recordAudioController
- (IBAction)buttonPressed{
	[recordAudioController startRecording];
}
- (void) startRecording{
	
	UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop" style:UIBarButtonItemStyleBordered  target:self action:@selector(stopRecording)];
	self.navigationItem.rightBarButtonItem = stopButton;
	[stopButton release];
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *err = nil;
	[audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
	if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
	}
	[audioSession setActive:YES error:&err];
	err = nil;
	if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
	}
	
	NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];

	[recordSetting setValue :[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVFormatIDKey];
	[recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
	[recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
	
	[recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
	[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
	[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
	
	
	
	// Create a new dated file
	NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSString *caldate = [now description];
	NSString *recorderFilePath = [[NSString stringWithFormat:@"%@/%@.caf", DOCUMENTS_FOLDER, caldate] retain];
	
	NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
	err = nil;
	AVAudioRecorder *recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&err];
	if(!recorder){
        NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
								   message: [err localizedDescription]
								  delegate: nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
	}
	
	//prepare to record
	//[recorder setDelegate:self];
	[recorder prepareToRecord];
	recorder.meteringEnabled = YES;
	
	BOOL audioHWAvailable = audioSession.inputIsAvailable;
	if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
								   message: @"Audio input hardware not available"
								  delegate: nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
        [cantRecordAlert show];
        [cantRecordAlert release]; 
        return;
	}
	
	// start recording
	[recorder recordForDuration:(NSTimeInterval) 10];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
