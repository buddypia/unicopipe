#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#define MakeStringCopy( _x_ ) ( _x_ != NULL && [_x_ isKindOfClass:[NSString class]] ) ? strdup( [_x_ UTF8String] ) : NULL

#define GetStringParam( _x_ ) ( _x_ != NULL ) ? [NSString stringWithUTF8String:_x_] : [NSString stringWithUTF8String:""]

extern "C"
{
	void _SetClipboard(const char* text)
	{
		[UIPasteboard generalPasteboard].string = GetStringParam(text);
	}

	char *_GetClipboard()
	{
		NSString *text = [UIPasteboard generalPasteboard].string;
		return MakeStringCopy(text);
	}
}
