//
//  peegViewController.m
//  peeg
//

#import "peegViewController.h"
#import "CMOpenALSoundManager.h"

enum mySoundIds {
	AUDIOEFFECT
};

@interface peegViewController()
	@property (nonatomic, retain) CMOpenALSoundManager *soundMgr;
@end

@implementation peegViewController

@synthesize soundMgr;
@synthesize touchPitch;

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	//start the audio manager...
	self.soundMgr = [[[CMOpenALSoundManager alloc] init] autorelease];
	soundMgr.soundFileNames = [NSArray arrayWithObject:@"snort.aiff"];
}

- (void)updatePitchFromTouches:(NSSet *)touches{
	UITouch * touch = [touches anyObject];
	CGPoint pos = [touch locationInView: [UIApplication sharedApplication].keyWindow];
	NSLog(@"Position of touch: %.3f, %.3f", pos.x, pos.y);
	//Height ranges from 1 - 480 => top - bottom
	//Usable pitch is in the range of: 0.6 - 1.4
	self.touchPitch = (pos.y / 480) + 0.5;
	NSLog(@"Touch pitch value: %.3f", self.touchPitch);
	
	soundMgr.pitch = self.touchPitch;
	[soundMgr playSoundWithID:AUDIOEFFECT];
	
}

#pragma mark Shakes
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
	[soundMgr playSoundWithID:AUDIOEFFECT];
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event{
	[soundMgr playSoundWithID:AUDIOEFFECT];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
	[soundMgr playSoundWithID:AUDIOEFFECT];
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event { 
    [self updatePitchFromTouches:touches]; 
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self updatePitchFromTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { 
    [self updatePitchFromTouches:touches]; 
} 
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event { 
    [self updatePitchFromTouches:touches]; 
}

#pragma mark - CleanUp
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.soundMgr = nil;
}


- (void)dealloc {
	[soundMgr dealloc];
	
    [super dealloc];
}

@end
