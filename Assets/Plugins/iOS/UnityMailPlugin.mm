//
//  UnityMailPlugin.mm
//  Unity-iPhone
//
//  Created by Lee Junho on 2015/08/03.
//
//
#if UNITY_VERSION <= 434
#import "iPhone_View.h"
#endif
#import <MessageUI/MessageUI.h>

#define UnityStringToNSString(_x_) ((_x_ != NULL) ? [NSString stringWithUTF8String:_x_] : [NSString stringWithUTF8String:""])

extern "C" void UnitySendMessage(const char *, const char *, const char *);

@interface UnityMailPlugin : UIViewController <MFMailComposeViewControllerDelegate>

@property(nonatomic,strong) NSString *gameObjectName;
@property(nonatomic,strong) NSString *methodName;
@property(nonatomic) BOOL isOpen;
@property(nonatomic) BOOL hasCallback;

-(BOOL)canSendMail;
-(void)showMailForm: (NSString *)to subject:(NSString *)subject body:(NSString *)body isHTML:(BOOL) isHTML attachFilePathList:(NSArray *)attachFilePathList;
-(void)registerCallback: (NSString *)callback method:(NSString *)method;
-(NSString *)makeFilePathToMimeType:(NSString *)filePath;
@end

@implementation UnityMailPlugin

static UnityMailPlugin* _instance = nil;

@synthesize gameObjectName;
@synthesize methodName;
@synthesize isOpen;
@synthesize hasCallback;

// Sigleton
+(UnityMailPlugin *)instance
{
    @synchronized(self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
            _instance.isOpen = NO;
        }
    }
    return _instance;
}

// Delegate
- (void)mailComposeController:( MFMailComposeViewController* )controller didFinishWithResult:( MFMailComposeResult )result error:( NSError* )error
{
    NSString *resultType = nil;
    
    if( error != nil )
    {
        resultType = @"NotSent";
    }
    else
    {
        switch( result )
        {
            case MFMailComposeResultSent:
                resultType = @"Canceled";
                break;
            case MFMailComposeResultSaved:
                resultType = @"Saved";
                break;
            case MFMailComposeResultCancelled:
                resultType = @"Cancelled";
                break;
            case MFMailComposeResultFailed:
                resultType = @"Failed";
                break;
            default:
                resultType = @"NotSent";
                break;
        }
    }
    
    [UnityGetGLViewController() dismissModalViewControllerAnimated:YES ];
    self.isOpen = false;
    
    if (self.hasCallback)
    {
        UnitySendMessage([self.gameObjectName UTF8String],[self.methodName UTF8String],[resultType UTF8String]);
    }
}

-(BOOL)canSendMail
{
    if([MFMailComposeViewController canSendMail]){
        return YES;
    }
    else {
        return NO;
    }
}
-(void)showMailForm: (NSString *)to subject:(NSString *)subject body:(NSString *)body isHTML:(BOOL) isHTML attachFilePathList:(NSArray *)attachFilePathList

{
    //    self.gameObjectName = callback;
    //    self.methodName = method;
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    
    [mc setSubject:subject];
    
    NSArray *toRecipients = [NSArray arrayWithObject:to];
    [mc setToRecipients:toRecipients];
    
    // Attach Files
    if ( attachFilePathList!=nil && [attachFilePathList count]>0 )
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for(NSString *path in attachFilePathList)
        {
            if ( [fileManager fileExistsAtPath:path]==NO )
            {
                continue;
            }
            
            NSData *data = [NSData dataWithContentsOfFile:path];
            if ( [data length]==0 )
            {
                continue;
            }
            
            NSString *mimeType = [self makeFilePathToMimeType:path];
            NSString *fileName = [path lastPathComponent];
            [mc addAttachmentData:data mimeType:mimeType fileName:fileName];
        }
    }
    
    [mc setMessageBody:body isHTML:isHTML];
    
    // Unity画面の上にビューを表示させる
    [UnityGetGLViewController() presentViewController:mc animated:YES completion:NULL];
    
    self.isOpen = true;
}

-(void)registerCallback: (NSString *)callback method:(NSString *)method
{
    self.gameObjectName = callback;
    self.methodName = method;
    
    // コールバッグあり
    self.hasCallback = true;
}

// ファイル拡張子によるmimeType文字列生成
// 対応しているのはpng,jpg(or jpeg)
// それ以外はapplication/octet-streamで返却する
-(NSString *)makeFilePathToMimeType:(NSString *)filePath
{
    NSDictionary *mimeTypeDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"png",@"image/png",
                                 @"jpg",@"image/jpg",
                                 @"jpeg",@"image/jpg",
                                 nil];
    
    NSString *extension = [filePath pathExtension];
    NSString *mimeType = [mimeTypeDic objectForKey:extension];
    if ( mimeType==nil ){ mimeType = @"application/octet-stream";}
    
    return mimeType;
}

@end

extern "C"{
    bool _UnityMailPlugin_CanSendMail();
    void _UnityMailPlugin_ShowMailForm(const char* to,const char* subject,const char* body, bool isHTML,const char** attachFilePathList,int attachFileCount);
    void _UnityMailPlugin_RegisterCallback(const char* callback,const char* method);
}

bool _UnityMailPlugin_CanSendMail()
{
    if([[UnityMailPlugin instance] canSendMail] && [UnityMailPlugin instance].isOpen == NO)
    {
        return YES;
    }
    else {
        return NO;
    }
}
void _UnityMailPlugin_ShowMailForm(const char* to,const char* subject,const char* body,bool isHTML, const char** attachFilePathList, int attachFileCount)
{
    if ([[UnityMailPlugin instance] canSendMail])
    {
        NSMutableArray *filePathArray = [NSMutableArray array];
        
        for(int i=0;i<attachFileCount;i++)
        {
            NSString *path = UnityStringToNSString(attachFilePathList[i]);
            [filePathArray addObject:path];
        }
        
        [[UnityMailPlugin instance] showMailForm:UnityStringToNSString(to)
                                         subject:UnityStringToNSString(subject)
                                            body:UnityStringToNSString(body)
                                          isHTML:((isHTML==true)? YES:NO)
                              attachFilePathList:filePathArray
         ];
    }
}

void _UnityMailPlugin_RegisterCallback(const char* callback,const char* method)
{
    [[UnityMailPlugin instance] registerCallback:UnityStringToNSString(callback) method:UnityStringToNSString(method)];
}