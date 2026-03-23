//
//  recordAudioController.h
//  peeg
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface recordAudioController : UIViewController {
	UIButton	*recordAudioController;
	AVAudioRecorder *recorder;
}

- (IBAction)buttonPressed;
- (void)startRecording;
- (void)stopRecording;

@end
