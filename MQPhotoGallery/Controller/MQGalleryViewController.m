//
//  MQGalleryViewController.m
//  MQPhotoGallery
//
//  Created by Premal Mistry on 12/9/14.
//  Copyright (c) 2014 Premal Mistry. All rights reserved.
//

#import "MQGalleryViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "PhotoCell.h"
#import "DisplaySelectedPhotoViewController.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark -
#pragma mark - MQGalleryViewController Private Members

@interface MQGalleryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, DBRestClientDelegate>
@property (nonatomic, strong) NSMutableArray *fileArray;
@property (nonatomic, strong) DBRestClient *restClient;

@property (weak, nonatomic) IBOutlet UICollectionView *photoGallery;

@end

#pragma mark -
#pragma mark - MQGalleryViewController

@implementation MQGalleryViewController

#pragma mark -
#pragma mark - View controller life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setupModel];
    [self setupUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Setup

- (void) setupModel {
    [self setupRestClient];
}

- (void) setupUI {
    [self linkAppToDropbox];
    [self loadFiles];
}

- (void) refreshPhotoGallery {
    [self.photoGallery reloadData];
}

#pragma mark -
#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.fileArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    
    DBMetadata *file = self.fileArray[indexPath.row];
    NSString* localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:file.filename];
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath: localPath] ) {
        cell.thumbnail.image = [UIImage imageWithContentsOfFile:localPath];
        cell.filename.text = file.filename;
        
    } else {
        if ( file.thumbnailExists ) {
            [self.restClient loadThumbnail:file.path ofSize:@"m" intoPath:localPath];
            
        } else {
            // Thumbnail does not exists for this photo, so try to load the original image
            [self.restClient loadFile:file.path intoPath:localPath];
        }
        
        cell.thumbnail.image = nil;
        cell.filename.text = @"Loading...";
    }
    
    cell.layer.borderWidth = 0.5f;
    cell.layer.borderColor = [UIColor colorWithRed:0.0f green:0.47f blue:1.0f alpha:1.0f].CGColor;
    
    // NSLog(@"Filename: %@", file.filename);
    // NSLog(@"Filepath: %@", localPath);
    
    return cell;
}

#pragma mark -
#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Segue from storyboard
}

#pragma mark -
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if( [segue.identifier isEqualToString:@"DisplaySelectedPhotoSegue"] ) {

        DisplaySelectedPhotoViewController* dspvc = (DisplaySelectedPhotoViewController*) segue.destinationViewController;
        NSIndexPath* indexPath = [self.photoGallery indexPathForCell:sender];
        DBMetadata* file = self.fileArray[indexPath.row];
        dspvc.imageFilePath = file.path;
    }
}

#pragma mark -
#pragma mark - Dropbox Setup API's

- (void) linkAppToDropbox {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
}

- (void) setupRestClient {
    if ( !_restClient && [[DBSession sharedSession] isLinked] ) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
}

#pragma mark - Listing files (Dropbox)

- (void) loadFiles {
    [self.restClient loadMetadata:@"/"];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        _fileArray = [[NSMutableArray alloc] init];
        for (DBMetadata *file in metadata.contents) {
            // Filter only popular image file types
            if ( [self isImage:file.filename] ) {
                [self.fileArray addObject:file];
            }
            NSLog(@"Filename: %@", file.filename);
        }

        // Sort files in descending order based on lastModifiedDate. (Most recent photos first)
        if ([self.fileArray count]) {
            NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"lastModifiedDate"  ascending:NO selector:@selector(compare:)];
            [self.fileArray sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
        }
    }
    
    [self refreshPhotoGallery];
}

- (BOOL) isImage: (NSString*) filename {
    NSString* fileExtension = [[filename pathExtension] lowercaseString];
    if ([fileExtension isEqualToString:@"png"] ||
        [fileExtension isEqualToString:@"jpg"] ||
        [fileExtension isEqualToString:@"jpeg"] ||
        [fileExtension isEqualToString:@"tiff"] ||
        [fileExtension isEqualToString:@"tif"] ||
        [fileExtension isEqualToString:@"bmp"]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Load file (Dropbox)

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSLog(@"File loaded into path: %@", localPath);
    
    [self refreshPhotoGallery];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"There was an error loading the file: %@", error);
}

#pragma mark - Load thumbnail (Dropbox)

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata {
    NSLog(@"Thumbnail loaded into path: %@", destPath);
    
    [self refreshPhotoGallery];
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error {
    NSLog(@"There was an error loading the file: %@", error);
    
}

@end
