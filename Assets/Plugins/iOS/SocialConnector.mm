//
//  SocialConnector.mm
//  Unity-iPhone
//
//  Created by Ando Keigo on 2012/12/08.
//
//
#import <QuartzCore/QuartzCore.h>
#import "Social/Social.h"

#define TWITTER 0
#define FACEBOOK 1
#define LINE 2

extern "C" {

@interface SocialActivity : UIActivity

- (id)initWithName:(NSString *)title scheme:(NSString *)scheme bundleIdentifier:(NSString *)bundleIdentifier;

+ (id)_activityFunctionImage:(id)arg1;

+ (id)_activityGenericImage:(id)arg1;

+ (id)_activityImageForApplication:(id)arg1;
@end

@implementation SocialActivity

NSString *_title;
NSString *_scheme;
NSString *_bundleIdentifier;
NSArray *_activityItems;
NSString *_imageName;

void *(^_myblock)(void);

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

- (id)initWithTitle:(NSString *)title scheme:(NSString *)scheme bundleIdentifier:(NSString *)bundleIdentifier action:myblock {
    _title = title;
    _scheme = scheme;
    _bundleIdentifier = bundleIdentifier;
    _myblock = [myblock copy];
    return self;
}

- (BOOL)isInstalled {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:_scheme]];
}

- (NSString *)activityType {
    return _bundleIdentifier;
}

- (NSString *)activityTitle {
    return _title;
}

- (UIImage *)_activityImage {
    if ([self isInstalled]) {
        return [UIImage imageNamed:_imageName];
    }
    else {
        return nil;
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;

}

- (void)prepareWithActivityItems:(NSArray *)activityItems; {
    _activityItems = activityItems;
    [super prepareWithActivityItems:activityItems];
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)performActivity {

    _myblock();

    [self activityDidFinish:YES];
}

- (void)activityDidFinish:(BOOL)completed {
    [super activityDidFinish:completed];
}
@end

void SocialConnector_Share(const char *text, const char *url, const char *textureURL) {

    NSString *_text = [NSString stringWithUTF8String:text ? text : ""];
    NSString *_url = [NSString stringWithUTF8String:url ? url : ""];
    NSString *_textureURL = [NSString stringWithUTF8String:textureURL ? textureURL : ""];

    UIImage *image = nil;

    if ([_textureURL length] != 0) {
        image = [UIImage imageWithContentsOfFile:_textureURL];
    }

    NSArray *actItems = [NSArray arrayWithObjects:_text, _url, image, nil];

    SocialActivity *social = [[SocialActivity alloc] initWithTitle:@"LINE" scheme:@"line://" bundleIdentifier:@"jp.naver.line" action:^() {

        NSString *contentType;
        NSString *contentKey;

        if ([_textureURL length] != 0) {
            UIImage *image = [UIImage imageWithContentsOfFile:_textureURL];
            if (image == nil) {
                return;
            }

            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.image = image;
            contentType = @"image";
            contentKey = pasteboard.name;

        } else if ([_text length] != 0) {
            contentType = @"text";
            contentKey = _text;

            if ([_url length] != 0) {
                contentKey = [contentKey stringByAppendingFormat:@" - %@", _url];
            }
        }

        NSString *lineUrlString = [NSString stringWithFormat:@"line://msg/%@/%@", contentType, contentKey];

        lineUrlString = [lineUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:lineUrlString]];

    }];

    NSArray *myItems = [NSArray arrayWithObjects:social, nil];
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:actItems applicationActivities:myItems];

    [UnityGetGLViewController() presentViewController:activityView animated:YES completion:nil];
}

void SocialConnector_PostMessage(const int *type, const char *text, const char *url, const char *textureURL) {

    NSString *_text = [NSString stringWithUTF8String:text ? text : ""];
    NSString *_url = [NSString stringWithUTF8String:url ? url : ""];
    NSString *_textureURL = [NSString stringWithUTF8String:textureURL ? textureURL : ""];


    if (type == (int const *) LINE) {
        NSString *contentType;
        NSString *contentKey;

        if ([_textureURL length] != 0) {
            UIImage *image = [UIImage imageWithContentsOfFile:_textureURL];
            if (image == nil) {
                return;
            }

            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.image = image;
            contentType = @"image";
            contentKey = pasteboard.name;

        } else if ([_text length] != 0) {
            contentType = @"text";
            contentKey = _text;

            if ([_url length] != 0) {
                contentKey = [contentKey stringByAppendingFormat:@"%%20%%2d%%20%@", _url];
            }
        }
        contentKey = [contentKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        NSURL *lineUrl = [NSURL URLWithString:[NSString stringWithFormat:@"line://msg/%@/%@", contentType, contentKey]];

        [[UIApplication sharedApplication] openURL:lineUrl];

    } else {

        SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:type == TWITTER ? SLServiceTypeTwitter : SLServiceTypeFacebook];

        composeViewController.completionHandler = ^(SLComposeViewControllerResult res) {
            if (res == SLComposeViewControllerResultCancelled) {
                // Cancel
                // UnitySendMessage(<#(char const *)obj#>, <#(char const *)method#>, <#(char const *)msg#>)
            }
            else if (res == SLComposeViewControllerResultDone) {
                // done!
                // UnitySendMessage(<#(char const *)obj#>, <#(char const *)method#>, <#(char const *)msg#>)
            }
            [composeViewController dismissViewControllerAnimated:YES completion:nil];
        };

        if ([_text length] != 0) {
            [composeViewController setInitialText:_text];
        }
        if ([_url length] != 0) {
            [composeViewController addURL:[NSURL URLWithString:_url]];
        }
        if ([_textureURL length] != 0) {
            UIImage *image = [UIImage imageWithContentsOfFile:_textureURL];
            if (image != nil) {
                [composeViewController addImage:image];
            }
        }

        [UnityGetGLViewController() presentViewController:composeViewController animated:YES completion:nil];
    }
}
}