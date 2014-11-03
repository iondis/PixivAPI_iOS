//
//  DetailInfoContainerViewController.m
//  RankingLog
//
//  Created by Zhou Hao on 14/11/3.
//  Copyright (c) 2014年 Zhou Hao. All rights reserved.
//

#import "DetailInfoContainerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "PixivAPI.h"

@interface DetailInfoContainerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *preloadProgress;

@end

@implementation DetailInfoContainerViewController

- (NSInteger)currentIllustId
{
    if (!self.illust)
        return -1;
    if ([self.illust isKindOfClass:[SAPIIllust class]]) {
        SAPIIllust *SAPI_illust = (SAPIIllust *)self.illust;
        return SAPI_illust.illustId;
    } else if ([self.illust isKindOfClass:[PAPIIllust class]]) {
        PAPIIllust *PAPI_illust = (PAPIIllust *)self.illust;
        return PAPI_illust.illust_id;
    }
    return 0;
}

- (void)updateEmbedView
{
    self.label.text = @"";
    self.image.image = nil;
    self.favoriteButton.imageView.image = [UIImage imageNamed:@"Star"];
    self.favoriteButton.tag = 0;
    
    if (!self.illust)
        return;

    if ([self.illust isKindOfClass:[SAPIIllust class]]) {
        SAPIIllust *SAPI_illust = (SAPIIllust *)self.illust;
        self.label.text = SAPI_illust.authorName;

    } else if ([self.illust isKindOfClass:[PAPIIllust class]]) {
        PAPIIllust *PAPI_illust = (PAPIIllust *)self.illust;
        self.label.text = PAPI_illust.name;
        [self.image sd_setImageWithURL:[NSURL URLWithString:PAPI_illust.profile_url_px_50x50]
                      placeholderImage:[UIImage imageNamed:@"placeholder"] options:SDWebImageLowPriority
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 NSLog(@"  fetch author=%ld profile 50x50 complete.", (long)PAPI_illust.author_id);
                             }];

        if (PAPI_illust.favorite_id != 0) {
            self.favoriteButton.imageView.image = [UIImage imageNamed:@"StarBlack"];
            self.favoriteButton.tag = PAPI_illust.favorite_id;      // storage favorite_id in tag, so can delete favorite later
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateDownloadProgress:-1.0];
    [self updatePreloadProgress:-1.0];
    
    [self updateEmbedView];
}

#pragma mark - UI

- (void)updateDownloadProgress:(float)progress
{
    if (progress > 0.0) {
        [self.downloadProgress setHidden:NO];
        self.downloadProgress.progress = progress;
    } else {
        [self.downloadProgress setHidden:YES];
    }
}
- (void)updatePreloadProgress:(float)progress
{
    if (progress > 0.0) {
        [self.preloadProgress setHidden:NO];
        self.preloadProgress.progress = progress;
    } else {
        [self.preloadProgress setHidden:YES];
    }
}

- (IBAction)favoriteWork:(UIButton *)sender
{
    NSInteger illust_id = [self currentIllustId];
    if (illust_id > 0) {
        NSInteger favorite_id = sender.tag;
        if (favorite_id == 0) {
            NSLog(@"add favorite: illustid=%ld", (long)illust_id);
            sender.imageView.image = [UIImage imageNamed:@"StarBlack"];
            
            [[PixivAPI sharedInstance] asyncBlockingQueue:^{
                NSInteger new_favorite_id = [[PixivAPI sharedInstance] PAPI_add_favorite_works:illust_id publicity:YES];
                [[PixivAPI sharedInstance] onMainQueue:^{
                    if (new_favorite_id > 0) {
                        [SVProgressHUD showSuccessWithStatus:@"Add success!"];
                    } else {
                        [SVProgressHUD showErrorWithStatus:@"Add error!"];
                        sender.imageView.image = [UIImage imageNamed:@"Star"];
                    }
                }];
            }];
            
        } else {
            NSLog(@"del favorite: favorite_id=%ld", (long)sender.tag);
            sender.imageView.image = [UIImage imageNamed:@"Star"];
            
            [[PixivAPI sharedInstance] asyncBlockingQueue:^{
                BOOL success = [[PixivAPI sharedInstance] PAPI_del_favorite_works:favorite_id];
                [[PixivAPI sharedInstance] onMainQueue:^{
                    if (success) {
                        [SVProgressHUD showSuccessWithStatus:@"Del success!"];
                    } else {
                        [SVProgressHUD showErrorWithStatus:@"Del error!"];
                        sender.imageView.image = [UIImage imageNamed:@"StarBlack"];
                    }
                }];
            }];
            
        }
    }
}

@end