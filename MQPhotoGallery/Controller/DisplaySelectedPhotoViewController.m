//
//  DisplaySelectedPhotoViewController.m
//  MQPhotoGallery
//
//  Created by Premal Mistry on 12/10/14.
//  Copyright (c) 2014 Premal Mistry. All rights reserved.
//

#import "DisplaySelectedPhotoViewController.h"
#import <DropboxSDK/DropboxSDK.h>

#pragma mark -
#pragma mark - DisplaySelectedPhotoViewController Private Members

@interface DisplaySelectedPhotoViewController () <DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *restClient;

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingImageProgressActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *loadingImageProgressLabel;
@property (weak, nonatomic) IBOutlet UILabel *filenameLabel;

@end

#pragma mark -
#pragma mark - DisplaySelectedPhotoViewController

@implementation DisplaySelectedPhotoViewController

#pragma mark -
#pragma mark - View controller life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupRestClient];
    [self setupUI];
    [self loadImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Setup

- (void) setupUI {
    self.filenameLabel.text = [self.imageFilePath lastPathComponent];
    [self showDownloadProgress:YES];
}

- (void) loadImage {
    // Load original downloaded images into '/Documents/DropboxDownloads' folder
    NSString* localDownloadDirectory = [self createDropboxDownloadsDirectory];
    NSString* filename = [self.imageFilePath lastPathComponent];
    NSString* filepath = [localDownloadDirectory stringByAppendingPathComponent:filename];
    NSString* dropboxFilePath = [NSString stringWithFormat:@"/%@", filename];
    
    [self.restClient loadFile:dropboxFilePath intoPath:filepath];
}

- (void) showDownloadProgress: (BOOL) show {
    self.loadingImageProgressActivityIndicator.hidden = !show;
    self.loadingImageProgressLabel.hidden = !show;
    
    if (show) {
        [self.loadingImageProgressActivityIndicator startAnimating];
        
    } else {
        [self.loadingImageProgressActivityIndicator stopAnimating];
    }
}

#pragma mark -
#pragma mark - Dropbox Setup API's

- (void) setupRestClient {
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
}

#pragma mark -
#pragma mark - Load file (Dropbox)

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSLog(@"File loaded into path: %@", localPath);
    
    self.photoImageView.image = [UIImage imageWithContentsOfFile:localPath];
    [self showDownloadProgress:NO];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"There was an error loading the file: %@", error);
    
    self.photoImageView.image = nil;
    [self showDownloadProgress:NO];
}

#pragma mark -
#pragma mark - Utility

- (NSString*) createDropboxDownloadsDirectory {
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localDownloadDirectory = [documentsDirectory stringByAppendingPathComponent:@"DropboxDownloads"];
    
    BOOL isDir;
    if (![fileManager fileExistsAtPath:localDownloadDirectory isDirectory:&isDir]) {
        if  ([fileManager createDirectoryAtPath:localDownloadDirectory withIntermediateDirectories:NO attributes:nil error:nil]) {
            NSLog(@"/Documents/DropboxDownloads directory created.");
            return localDownloadDirectory;
            
        } else {
            NSLog(@"Fail to create /Documents/DropboxDownloads.");
            return NSTemporaryDirectory();
        }
    } else {
        NSLog(@"/Documents/DropboxDownloads directory already exists.");
        return localDownloadDirectory;
    }
}


@end
