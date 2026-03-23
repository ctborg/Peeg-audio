//
//  CMOpenALSoundManager.m
//
//  Created by Alex Restrepo on 5/19/09.
//  Copyright 2009 Colombiamug. All rights reserved.
//
//	Portions of this code are adapted from Apple's oalTouch example and
//	http://www.gehacktes.net/2009/03/iphone-programming-part-6-multiple-sounds-with-openal/
//
//  This code is released under the creative commons attribution-share alike licence, meaning:
//
//	Attribution - You must attribute the work in the manner specified by the author or licensor 
//	(but not in any way that suggests that they endorse you or your use of the work).
//	In this case, simple credit somewhere in your app or documentation will suffice.
//
//	Share Alike - If you alter, transform, or build upon this work, you may distribute the resulting
//	work only under the same, similar or a compatible license.
//	Simply put, if you improve upon it, share!
//
//	http://creativecommons.org/licenses/by-sa/3.0/us/

#import "CMOpenALSoundManager.h"
#import "CMOpenALSound.h"
#import "SynthesizeSingleton.h"
#import "DebugOutput.h"

@interface CMOpenALSoundManager()
@property (nonatomic, retain) NSMutableDictionary *soundDictionary;
@property (nonatomic, retain) AVAudioPlayer *backgroundAudio;
@property (nonatomic) BOOL interrupted;
@property (nonatomic) BOOL isiPodAudioPlaying;
@property (nonatomic, copy) NSString *currentBackgroundAudioFile;
@end

@interface CMOpenALSoundManager(private)
- (NSString *) keyForSoundID:(NSUInteger)soundID;
- (void) setupAudioCategorySilenceIpod:(BOOL)silenceIpod;
- (void) shutdownOpenAL;
- (BOOL) startupOpenAL;
@end

@implementation CMOpenALSoundManager
@synthesize soundDictionary, soundFileNames, backgroundAudio, isiPodAudioPlaying, interrupted, currentBackgroundAudioFile, pitch;

#if USE_AS_SINGLETON
SYNTHESIZE_SINGLETON_FOR_CLASS(CMOpenALSoundManager);
#endif

#pragma mark -
#pragma mark init/dealloc
- (id) init
{
	self = [super init];		
	if (self != nil) 
	{		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleAudioSessionInterruption:)
													 name:AVAudioSessionInterruptionNotification
												   object:[AVAudioSession sharedInstance]];
				
		self.soundDictionary = [NSMutableDictionary dictionary];
		self.soundEffectsVolume = 1.0;
		self.backgroundMusicVolume = 1.0;		

		//isiPodAudioPlaying = YES; 
		[self endInterruption];
	}
	return self;
}

// start up openAL
-(BOOL) startupOpenAL
{				
	ALCcontext	*context = NULL;
	ALCdevice	*device = NULL;

	// Initialization
	device = alcOpenDevice(NULL); // select the "preferred device"
	if(!device) return NO;
		
	// use the device to make a context
	context = alcCreateContext(device, NULL);
	if(!context) return NO;
	
	// set my context to the currently active one
	alcMakeContextCurrent(context);
	
	debug(@"oal inited ok");
	return YES;	
}

- (void) dealloc
{
	debug(@"CMOpenALSoundManager dealloc");

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self shutdownOpenAL];
	
	[backgroundAudio release];
	[soundFileNames release];
	[soundDictionary release];
	[currentBackgroundAudioFile release];

	[super dealloc];
}

- (void) shutdownOpenAL
{
	//self.backgroundAudio = nil;
	//self.soundFileNames = nil;
	//self.soundDictionary = nil;
	
	ALCcontext	*context = NULL;
    ALCdevice	*device = NULL;
	
	//Get active context (there can only be one)
    context = alcGetCurrentContext();
	if(!context) return;
	
    //Get device for active context
    device = alcGetContextsDevice(context);

	alcMakeContextCurrent(NULL);
	
    //Release context
    alcDestroyContext(context);
	
    //Close device
    if(device) alcCloseDevice(device);
}

#pragma mark -
#pragma mark audio session mgmt

- (void) beginInterruption
{		
	debug(@"begin interruption");
	[self stopBackgroundMusic];
	[self purgeSounds];
	[self shutdownOpenAL];
	
	NSError *error = nil;
	[[AVAudioSession sharedInstance] setActive:NO error:&error];
	if(error)
	{
		debug(@"Failed to deactivate AVAudioSession: %@", error);
	}
}

- (void) endInterruption
{
	debug(@"end interruption");	
	[self setupAudioCategorySilenceIpod: NO];
	[self startupOpenAL];	

	NSError *error = nil;
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
	if(error)
	{
		debug(@"Failed to activate AVAudioSession: %@", error);
	}
}

- (void) setupAudioCategorySilenceIpod:(BOOL)silenceIpod;
{
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	BOOL audioIsAlreadyPlaying = [audioSession isOtherAudioPlaying];
	NSError *error = nil;

	debug(@"isOtherAudioPlaying = %@", audioIsAlreadyPlaying ? @"YES" : @"NO");
	
	if(audioIsAlreadyPlaying && !silenceIpod)
	{
		self.isiPodAudioPlaying = YES;
		
		[audioSession setCategory:AVAudioSessionCategoryAmbient error:&error];
	}
	else
	{
		self.isiPodAudioPlaying = NO;
		
		[audioSession setCategory:AVAudioSessionCategorySoloAmbient error:&error];
	}

	if(error)
	{
		debug(@"Failed to configure AVAudioSession category: %@", error);
	}
}

- (void) handleAudioSessionInterruption:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSNumber *typeNumber = [userInfo objectForKey:AVAudioSessionInterruptionTypeKey];

	if([typeNumber unsignedIntegerValue] == AVAudioSessionInterruptionTypeBegan)
	{
		debug(@"Start audio interruption");
		[self beginInterruption];
		self.interrupted = YES;
	}
	else if(self.interrupted)
	{
		debug(@"Stop audio interruption");
		[self endInterruption];
		self.interrupted = NO;
	}
}

#pragma mark -
#pragma mark cleanup
- (void) purgeSounds
{
	//call this if you get a memory warning, to unload all sounds from memory
	[self.soundDictionary removeAllObjects];	

	//if there's a background audio that's not playing, remove that too...
	if(![backgroundAudio isPlaying])
	{
		self.backgroundAudio = nil;
		self.currentBackgroundAudioFile = nil;
	}
}

#pragma mark -
#pragma mark background music playback
// plays a file as the background audio...
- (void) playBackgroundMusic:(NSString *)file
{
	[self playBackgroundMusic:file forcePlay:NO];
}

- (void) playBackgroundMusic:(NSString *)file forcePlay:(BOOL)forcePlay
{		
	if(forcePlay)	//if we want to kill other audio sources, like the iPod...
	{
		[backgroundAudio stop]; //if there's audio already playing...
		[self setupAudioCategorySilenceIpod:YES];
	}
	
	if(isiPodAudioPlaying) //if other background audio is playing bail out...
	{
		debug(@"Sry, ipod is playing... can't play file %@",file);
		return;
	}
	
	if(self.backgroundAudio && [self.currentBackgroundAudioFile isEqualToString:file])
	{
		[self.backgroundAudio play];
		return; //already playing
	}
	
	NSString *soundFilePath = [[NSBundle mainBundle] pathForResource: [file stringByDeletingPathExtension] 
															  ofType: [file pathExtension]];	
	
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	
	NSError *error = nil;
	AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL 
																   error:&error];
	
	[fileURL release];
	
	if(error)
	{
		//TODO:chequear por errores
		debug(@"***** ERROR creando backgroundMusicPlayer file:%@", file);
		[player release];
		return;
	}	
	
	self.currentBackgroundAudioFile = file;
	[player setNumberOfLoops:-1]; //loop forever
	player.volume = backgroundMusicVolume;
	[player play];		
	
	self.backgroundAudio = player;
	[player release];
}

- (void) stopBackgroundMusic
{
	[backgroundAudio stop];
}

- (void) pauseBackgroundMusic
{
	[backgroundAudio pause];
}

- (void) resumeBackgroundMusic
{
	[backgroundAudio play];
}

#pragma mark -
#pragma mark effects playback
// grab the filename (key) from the filenames array
- (NSString *) keyForSoundID:(NSUInteger)soundID
{
	if(soundID < 0 || soundID >= [soundFileNames count])
		return nil;
	
	return [[soundFileNames objectAtIndex:soundID] lastPathComponent];
}

- (void) playSoundWithID:(NSUInteger)soundID 
{	
	//get sound key
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];
	sound.pitch = self.pitch;
	if(!sound)
	{
		//create a new sound
		sound = [[CMOpenALSound alloc] initWithSoundFile:soundFile doesLoop:NO]; //this will return nil on failure
		
		if(!sound) //error
			return;
		
		[soundDictionary setObject:sound forKey:soundFile];
		[sound release];
	}
	
	[sound play];
	sound.volume = self.soundEffectsVolume;
}

- (void) stopSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];		
	[sound stop];
}

- (void) pauseSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];		
	[sound stop];
}

- (void) rewindSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];
	[sound rewind];
}

- (BOOL) isPlayingSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return NO;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];		
	return [sound isAnyPlaying];
}

- (BOOL) isBackGroundMusicPlaying
{
	return [backgroundAudio isPlaying];
}

#pragma mark -
#pragma mark properties
- (float) backgroundMusicVolume
{	
	return backgroundMusicVolume;
}

- (void) setBackgroundMusicVolume:(float) newVolume
{	
	backgroundMusicVolume = newVolume;
	backgroundAudio.volume = newVolume;
}

- (float) soundEffectsVolume
{
	return soundEffectsVolume;
}

- (void) setSoundEffectsVolume:(float) newVolume
{
	soundEffectsVolume = newVolume;
	for(NSString *key in soundDictionary)
	{
		((CMOpenALSound *)[soundDictionary objectForKey:key]).volume = newVolume;
	}
}
@end
