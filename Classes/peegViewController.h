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

@property (nonatomic) float touchPitch;

- (void)updatePitchFromTouches:(NSSet *)touches;

@end

