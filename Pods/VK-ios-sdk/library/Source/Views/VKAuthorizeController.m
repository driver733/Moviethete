//
//  VKAuthorizeController.m
//
//  Copyright (c) 2014 VK.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "VKAuthorizeController.h"
#import "VKBundle.h"

@implementation UINavigationController (LastControllerBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.viewControllers.count)
        return [[self.viewControllers lastObject] preferredStatusBarStyle];
    return UIStatusBarStyleDefault;
}
@end

@interface VKSdk ()
+ (BOOL)processOpenInternalURL:(NSURL *)passedUrl validation:(BOOL)validation;
@end

@interface VKAuthorizeController ()
@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) NSString *appId;
@property(nonatomic, strong) NSString *scope;
@property(nonatomic, strong) NSURL *redirectUri;
@property(nonatomic, strong) UIActivityIndicatorView *activityMark;
@property(nonatomic, strong) UILabel *warningLabel;
@property(nonatomic, strong) UILabel *statusBar;
@property(nonatomic, strong) VKError *validationError;
@property(nonatomic, strong) NSURLRequest *lastRequest;
@property(nonatomic, weak) UINavigationController *internalNavigationController;
@property(nonatomic, assign) BOOL finished;

@end

@implementation VKAuthorizeController

+ (void)presentForAuthorizeWithAppId:(NSString *)appId
                      andPermissions:(NSArray *)permissions
                        revokeAccess:(BOOL)revoke
                         displayType:(VKDisplayType)type {
    VKAuthorizeController *controller = [[VKAuthorizeController alloc] initWith:appId andPermissions:permissions revokeAccess:revoke displayType:type];
    [self presentThisController:controller];
}

+ (void)presentForValidation:(VKError *)validationError {
    VKAuthorizeController *controller = [[VKAuthorizeController alloc] init];
    controller.validationError = validationError;
    [self presentThisController:controller];
}

+ (void)presentThisController:(VKAuthorizeController *)controller {
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];

    if (VK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        navigation.navigationBar.barTintColor = VK_COLOR;
        navigation.navigationBar.tintColor = [UIColor whiteColor];
        navigation.navigationBar.translucent = YES;
    }
    if (VK_IS_DEVICE_IPAD) {
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        navigation.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }

    UIImage *image = [VKBundle vkLibraryImageNamed:@"ic_vk_logo_nb"];
    controller.navigationItem.titleView = [[UIImageView alloc] initWithImage:image];
    [navigation vks_presentViewControllerThroughDelegate];

    controller.internalNavigationController = navigation;
}

+ (NSURL *)buildAuthorizationURL:(NSString *)prefix
                     redirectUri:(NSString *)redirectUri
                        clientId:(NSString *)clientId
                           scope:(NSString *)scope
                          revoke:(BOOL)revoke
                         display:(NSString *)display {
    NSDictionary *params = @{
            @"v" : [[VKSdk instance] apiVersion],
            @"scope" : scope ?: @"",
            @"revoke" : @(revoke),
            @"display" : display ?: VK_DISPLAY_MOBILE,
            @"client_id" : clientId ?: @"",
            @"sdk_version" : VK_SDK_VERSION,
            @"redirect_uri" : redirectUri ?: @"",
            @"response_type" : @"token"
    };
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", prefix ?: @"https://oauth.vk.com/authorize", [VKUtil queryStringFromParams:params]]];
}

#pragma mark View prepare

- (void)loadView {
    [super loadView];
    if (VK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    view.backgroundColor = [UIColor colorWithRed:240.0f / 255 green:242.0f / 255 blue:245.0f / 255 alpha:1.0f];
    self.view = view;
    _activityMark = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_activityMark startAnimating];
    _activityMark.center = CGPointMake(view.frame.size.width / 2, view.frame.size.height / 2);
    _activityMark.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [view addSubview:_activityMark];

    _warningLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, _activityMark.frame.origin.y + _activityMark.frame.size.height + 20,
            self.view.frame.size.width - 20, 30)];
    _warningLabel.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _warningLabel.numberOfLines = 3;
    _warningLabel.hidden = YES;
    _warningLabel.textColor = VK_COLOR;
    _warningLabel.textAlignment = NSTextAlignmentCenter;
    _warningLabel.font = [UIFont boldSystemFontOfSize:15];
    _warningLabel.text = VKLocalizedString(@"Please check your internet connection");
    [view addSubview:_warningLabel];

    _webView = [[UIWebView alloc] initWithFrame:view.bounds];
    _webView.delegate = self;
    _webView.hidden = YES;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _webView.scalesPageToFit = YES;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.clipsToBounds = NO;
    [view addSubview:_webView];
    if (self.internalNavigationController) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VKBundle localizedString:@"Cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelAuthorization:)];
#else
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VKBundle localizedString:@"Cancel"] style:UIBarButtonItemStyleBordered target:self action:@selector(cancelAuthorization:)];
#endif
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self makeViewport];
}

- (instancetype)initWith:(NSString *)appId andPermissions:(NSArray *)permissions revokeAccess:(BOOL)revoke displayType:(VKDisplayType)display {
    self = [super init];
    _appId = appId;
    _scope = [permissions componentsJoinedByString:@","];
    _redirectUri = [[self class] buildAuthorizationURL:nil redirectUri:nil clientId:_appId scope:_scope revoke:revoke display:display];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startLoading];
}

- (void)startLoading {
    if (!self.redirectUri) {
        self.redirectUri = [NSURL URLWithString:self.validationError.redirectUri];

    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.redirectUri];

    [_webView loadRequest:request];
}

#pragma mark Web view work

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.lastRequest = request;
    NSString *urlString = [[request URL] absoluteString];
    self.statusBar.text = urlString;
    if (!webView.hidden && !self.navigationItem.rightBarButtonItem) {
        [self setRightBarButtonActivity];
    }
    if ([[[request URL] path] isEqual:@"/blank.html"]) {
        [self dismissWithAuthorizationCancellationState: NO completion:^{
            if ([VKSdk processOpenInternalURL:[request URL] validation:self.validationError != nil] && self.validationError) {
                [self.validationError.request repeat];
            } else if (self.validationError) {
                [self.validationError.request cancel];
            }
        }];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.finished) return;
    if ([error code] != NSURLErrorCancelled) {
        self.warningLabel.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^(void) {
            [webView loadRequest:_lastRequest];
            if (!self.navigationItem.rightBarButtonItem)
                [self setRightBarButtonActivity];
        });
    }
}

- (void)setRightBarButtonActivity {
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityView sizeToFit];
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    [activityView startAnimating];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:activityView] animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self makeViewport];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^(void) {
        _warningLabel.hidden = YES;
        webView.hidden = NO;
        self.navigationItem.rightBarButtonItem = nil;
    });
}

- (void)makeViewport {
    NSString *javaScript = [NSString stringWithFormat:@"viewport = document.querySelector('meta[name=viewport]'); viewport.setAttribute('content', 'width = %d, height = %d, initial-scale = 1.0, maximum-scale = 1.0, minimum-scale = 1.0, user-scalable=yes');", (int) self.webView.frame.size.width, (int) self.webView.frame.size.height];
    [_webView stringByEvaluatingJavaScriptFromString:javaScript];
}

#pragma mark Cancelation and dismiss

- (void)cancelAuthorization:(id)sender {
  [self dismissWithAuthorizationCancellationState: YES completion: ^{
        if (!_validationError) {
            //Silent cancel
            [VKSdk processOpenInternalURL:[NSURL URLWithString:@"#"] validation:NO];
        } else {
            [_validationError.request cancel];
        }
    }];
    if (_validationError) {
        NSError *error = [NSError errorWithVkError:[VKError errorWithCode:VK_AUTHORIZE_CONTROLLER_CANCEL]];
        if (_validationError.request.errorBlock) {
            _validationError.request.errorBlock(error);
        }
    }
}

- (void)dismissWithAuthorizationCancellationState:(BOOL)wasCancelled completion:(void (^)())completion {
    _finished = YES;

    if (_internalNavigationController.isBeingDismissed) {
        if (completion) {
            completion();
        }

        return;
    }

    if (!_internalNavigationController) {
        if (self.navigationController) {
            [self vks_viewControllerWillDismissWithAuthorizationCancellationState:wasCancelled];
            [self.navigationController popViewControllerAnimated:YES];
            if (completion) {
                completion();
            }
        } else if (self.presentingViewController) {
            [self vks_viewControllerWillDismissWithAuthorizationCancellationState:wasCancelled];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [self vks_viewControllerDidDismissWithAuthorizationCancellationState:wasCancelled];
                if (completion) {
                    completion();
                }
            }];
        }
    } else {
        [self vks_viewControllerWillDismissWithAuthorizationCancellationState:wasCancelled];
        [_internalNavigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [self vks_viewControllerDidDismissWithAuthorizationCancellationState:wasCancelled];
            completion();
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
