/**
 Protocol defining an object that can weakly hold a UIWindow
 */
@protocol BAMSGWindowHolder <NSObject>

@required

@property (nullable, weak) UIWindow *presentingWindow;
@property (nullable, weak) UIWindow *overlayedWindow;

@end
