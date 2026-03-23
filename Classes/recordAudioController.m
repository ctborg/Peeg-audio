//
//  recordAudioController.m
//  peeg
//

#import "recordAudioController.h"

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

@interface recordAudioController ()
- (void)showAlertWithMessage:(NSString *)message;
@end

@implementation recordAudioController
- (IBAction)buttonPressed{
	[self startRecording];
}
- (void) startRecording{
	
	UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop" style:UIBarButtonItemStylePlain  target:self action:@selector(stopRecording)];
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
	AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&err];
	if(!newRecorder){
        NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
		[self showAlertWithMessage:[err localizedDescription]];
		[recordSetting release];
		[recorderFilePath release];
        return;
	}
	
	//prepare to record
	//[newRecorder setDelegate:self];
	[newRecorder prepareToRecord];
	newRecorder.meteringEnabled = YES;
	
	BOOL audioHWAvailable = [audioSession availableInputs] != nil;
	if (! audioHWAvailable) {
		[self showAlertWithMessage:@"Audio input hardware not available"];
		[newRecorder release];
		[recordSetting release];
		[recorderFilePath release];
        return;
	}
	
	[recorder release];
	recorder = newRecorder;

	// start recording
	[recorder recordForDuration:(NSTimeInterval) 10];
	[recordSetting release];
	[recorderFilePath release];
}

- (void)stopRecording
{
	[recorder stop];
	self.navigationItem.rightBarButtonItem = nil;
}

- (void)showAlertWithMessage:(NSString *)message
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning"
																			 message:message
																	  preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK"
															style:UIAlertActionStyleDefault
														  handler:nil];
	[alertController addAction:dismissAction];
	[self presentViewController:alertController animated:YES completion:nil];
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
	[recorder release];
    [super dealloc];
}


@end
