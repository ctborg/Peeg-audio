//
//  peegViewController.h
//  peeg
//

@class CMOpenALSoundManager;
@interface peegViewController : UIViewController {
	CMOpenALSoundManager *soundMgr;
	UIImageView *snortView;
	float touchPitch;
}

@property (nonatomic, retain) CMOpenALSoundManager *soundMgr;
@property (nonatomic) float touchPitch;

- (void)updatePitchFromTouches:(NSSet *)touches;

@end
