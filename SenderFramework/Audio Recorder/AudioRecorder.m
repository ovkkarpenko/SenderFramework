//
//  AudioRecorder.m
//  SENDER
//
//  Created by Nick Gromov on 10/24/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "AudioRecorder.h"
#include <lame/lame.h>

NSString * const AudioRecorderWillStartRecording =  @"AudioRecorderWillStartRecording";
NSString * const AudioRecorderDidStopRecording = @"AudioRecorderDidStopRecording";
NSString * const AudioRecorderWillStartPlaying = @"AudioRecorderWillStartPlaying";
NSString * const AudioRecorderDidStopPlaying = @"AudioRecorderDidStopPlaying";

static AudioRecorder * staticInstance;

@interface AudioRecorder () {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    NSString * audioFilePath;
    CGFloat sampleRate;
}
- (void)setAudioFileDomain;

- (NSString *)getAudioFilePath;
@end

@implementation AudioRecorder

+ (AudioRecorder *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticInstance = [[AudioRecorder alloc] init];
    });
    
    return staticInstance;
}


- (id)init
{
    self = [super init];
    if(self)
    {
        // Setup audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        sampleRate  = 20050;
        // Define the recorder setting
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];

        [recordSetting setValue:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
        [recordSetting setValue:@(sampleRate) forKey:AVSampleRateKey];
        [recordSetting setValue:@2 forKey:AVNumberOfChannelsKey];
        [recordSetting setValue:@(AVAudioQualityLow) forKey:AVEncoderAudioQualityKey];
        
        // Initiate and prepare the recorder
        recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:[self getTemporaryDirectory]] settings:recordSetting error:nil];
        recorder.delegate = self;
        recorder.meteringEnabled = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioPlayerWillStartPlayingNotification:)
                                                     name:@"MWAudioPlayerWillPlay"
                                                   object:nil];
    }
    return self;
}

- (void)audioPlayerWillStartPlayingNotification:(NSNotification *)notification
{
    [self stopPlay];
    [self stopRecord];
}

- (NSString *)getAudioFilePath
{
    if (!audioFilePath) {
        [self setAudioFileDomain];
    }
    return audioFilePath;
}

- (void)setAudioFileDomain
{
    NSString * documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *pathComponents = @[documentsDirectory, @"MyAudioMemo.mp3"];
    [NSURL fileURLWithPathComponents:pathComponents];
    audioFilePath = [[pathComponents[0] stringByAppendingString:@"/"] stringByAppendingString:pathComponents[1]];
}

- (NSString *)getTemporaryDirectory
{
    return [NSTemporaryDirectory() stringByAppendingString:@"RecordedFile"];
}

- (void)startRecord
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioRecorderWillStartRecording
                                                        object:self
                                                      userInfo:nil];
    NSError * error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:&error];

    if (!error) {
        [self deleteFile];
        [recorder record];
    }
}

- (void)stopRecord
{
    if (!recorder.recording)
        return;

    [recorder stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioRecorderDidStopRecording
                                                        object:self
                                                      userInfo:nil];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError * error;
    [audioSession setActive:NO error:&error];
}

- (BOOL)playWithDelegate:(id<AVAudioPlayerDelegate>)delegate
{
    if (!recorder.recording) {
        NSError * error;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[self getTemporaryDirectory]] error:&error];
        if (!error)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:AudioRecorderWillStartPlaying
                                                                object:self
                                                              userInfo:nil];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [player setDelegate:delegate];
            [player setVolume:1];
            [player play];
            return YES;
        }
    }
    return NO;
}

- (float)getFileDuration
{
    return [self getDuration:[NSURL fileURLWithPath:[self getTemporaryDirectory]]];
}

- (float)getDuration:(NSURL *)url
{
    float duration = 0.0;
    @try {
        NSError * error;
        AVAudioPlayer * player1 = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        duration = player1.duration;
        player1 = nil;
        
    } @catch (NSException *exception) {
        
    } @finally {
        return duration/100;
    }
}


- (BOOL)playerStatus
{
    return player.playing;
}

- (void)stopPlay
{
    [player stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioRecorderDidStopPlaying
                                                        object:self
                                                      userInfo:nil];
}

- (NSTimeInterval)currentTime:(id)delegate
{
    if (player.delegate && player.delegate == delegate) {
        return player.currentTime;
    }
    return -1;
}

#pragma mark - convertToMp3

#if TARGET_IPHONE_SIMULATOR

- (BOOL)convertToMp3
{
    return NO;
}

#else

- (BOOL)convertToMp3
{
    NSString *cafFilePath = [self getTemporaryDirectory];
    
    
    NSString * mp3FilePath = [self getAudioFilePath];
    
    @try {
        size_t read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, sampleRate);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, (int)read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        return YES;
    }
    @catch (NSException *exception) {
        return NO;
    }
}

#endif

#pragma mark - manage file

- (NSData *)getFileData
{
    return [NSData dataWithContentsOfFile:[self getAudioFilePath]];
}

- (void)deleteFile
{
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[self getAudioFilePath] error:&error];
    if (!success) {
        // NSLog(@"Error removing document path: %@", error.localizedDescription);
    }
}

@end
