//
//  PhotoCell.h
//  MQPhotoGallery
//
//  Created by Premal Mistry on 12/9/14.
//  Copyright (c) 2014 Premal Mistry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *filename;
@end
