#import <Batch/BAMSGImageView.h>
#import <Batch/BAMSGImageDownloader.h>

@interface BAMSGRemoteImageView : BAMSGImageView

/**
 Same as calling -setImageURL:completion: with a nil completion block.
 */
- (void)setImageURL:(NSURL*)url;

/**
 Ask the image view to load the image at `url` and display it.
 @param url The url pointing to the remote or local (file url) image. Local and remote gif images are also supported.
 @param completion Can be nil. If image couldn't be downloaded, completion is called with a non-null error.
 */
- (void)setImageURL:(NSURL*)url completion:(void (^)(UIImage *, NSError *))completion;

@end
