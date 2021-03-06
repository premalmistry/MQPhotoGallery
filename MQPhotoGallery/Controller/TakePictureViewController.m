//
//  TakePictureViewController.m
//  MQPhotoGallery
//
//  Created by Premal Mistry on 12/10/14.
//  Copyright (c) 2014 Premal Mistry. All rights reserved.
//

#import "TakePictureViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <DropboxSDK/DropboxSDK.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark -
#pragma mark - TakePictureViewController Private Members

@interface TakePictureViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, DBRestClientDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) DBRestClient *restClient;

@property (weak, nonatomic) IBOutlet UIImageView *pictureView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadProgressActivityInidicator;
@property (weak, nonatomic) IBOutlet UILabel *uploadProgressLabel;
@end

#pragma mark -
#pragma mark - TakePictureViewController

@implementation TakePictureViewController

#pragma mark -
#pragma mark - View controller life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupRestClient];
    [self setupUI];
    [self launchCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - Setup

- (void) setupUI {
    [self showUploadProgress:NO];
    
    // Border around UIImageView
    self.pictureView.layer.borderWidth = 0.5f;
    self.pictureView.layer.borderColor = [UIColor colorWithRed:0.0f green:0.47f blue:1.0f alpha:1.0f].CGColor;
}

#pragma mark -
#pragma mark - Button click events

- (IBAction)uploadPicture:(UIButton *)sender {
    [self uploadPictureToDropboxRootFolder];
}

- (IBAction)takePicture:(UIButton*)sender {
    [self launchCamera];
}

#pragma mark -
#pragma mark - UIImagePickerController

- (BOOL) isCameraAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void) launchCamera {
    if ( [self isCameraAvailable] ) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        picker.mediaTypes = @[(NSString*)kUTTypeImage];
        [self presentViewController:picker animated:YES completion:NULL];
        
    } else {

#if TARGET_IPHONE_SIMULATOR
        [self launchPhotoLibrary];
#else
        // Oops! No camera found on this device, display error message to the user
        [self showAlert:@"Camera error" message:@"Your device does not support camera."];
#endif
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage* image = info[UIImagePickerControllerEditedImage];
    if (!image)
        image = info[UIImagePickerControllerOriginalImage];
    
    self.pictureView.image = image;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark -  Upload file (Dropbox API)

- (void) setupRestClient {
    if ( !_restClient && [[DBSession sharedSession] isLinked] ) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
}

- (void)uploadPictureToDropboxRootFolder {
    if (self.pictureView.image != nil) {
        
        // Start animating activity indicator to show the progress of file upload.
        [self showUploadProgress:YES];
        
        // Setup local file path
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filename = [NSString stringWithFormat:@"Photo_%@.png", [self currentTime]];
        NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
        
        // Save picture taken into PNG format
        NSData* data = UIImagePNGRepresentation(self.pictureView.image);
        [data writeToFile:filepath atomically:YES];
        
        // Upload file to dropbox root folder
        NSString *destDir = @"/";
        [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:filepath];
    }
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    
    [self showUploadProgress:NO];
    [self showAlert:@"Upload successful!" message:@"Your picture is successfully uploaded to Dropbox."];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
    
    [self showUploadProgress:NO];
    [self showAlert:@"Upload failed!" message:@"Failed to upload your picture to Dropbox. Please try again."];
}

- (void) showUploadProgress: (BOOL) show {
    self.uploadProgressActivityInidicator.hidden = !show;
    self.uploadProgressLabel.hidden = !show;
    
    if (show) {
        [self.uploadProgressActivityInidicator startAnimating];
        
    } else {
        [self.uploadProgressActivityInidicator stopAnimating];
    }
}

#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Upload successful!"]) {
        // Navigate back to Gallery
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark - Utility API's

- (NSString*) currentTime {
    NSDate *today = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:enUSPOSIXLocale];
    [df setDateFormat:@"yyyyMMddhhmmss"];
    return [df stringFromDate:today];
}

// Consider SVProgressHUD instead UIAlertView ?
- (void) showAlert:(NSString*) title message:(NSString*) message {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

// Launch photo library for debugging purpose (in simulator)
- (void) launchPhotoLibrary {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.mediaTypes = @[(NSString*)kUTTypeImage];
    [self presentViewController:picker animated:YES completion:NULL];
}



@end
