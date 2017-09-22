#import "RNSearchBarManager.h"

#import "RNSearchBar.h"

#import "RCTBridge.h"
#import "RCTUIManager.h"

@implementation RCTConvert (UIBarStyle)
RCT_ENUM_CONVERTER(UIBarStyle, (@{
                                  @"default": @(UIBarStyleDefault),
                                  @"black": @(UIBarStyleBlack)
                                  }),
                   UIBarStyleDefault, integerValue)
@end

@implementation RCTConvert (UISearchBarStyle)
RCT_ENUM_CONVERTER(UISearchBarStyle, (@{
                                        @"default": @(UISearchBarStyleDefault),
                                        @"prominent": @(UISearchBarStyleProminent),
                                        @"minimal": @(UISearchBarStyleMinimal)
                                        }),
                   UISearchBarStyleDefault, integerValue)
@end

@implementation RNSearchBarManager

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return _bridge.uiManager.methodQueue;
}


- (UIView *)view
{
  RNSearchBar *searchBar = [[RNSearchBar alloc] initWithEventDispatcher:self.bridge.eventDispatcher];

  return searchBar;
}

RCT_EXPORT_VIEW_PROPERTY(placeholder, NSString)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_CUSTOM_VIEW_PROPERTY(showsCancelButton, BOOL, RNSearchBar)
{
    BOOL value = [RCTConvert BOOL:json];
    view._jsShowsCancelButton = value;
    view.showsCancelButton = value;
}
RCT_EXPORT_VIEW_PROPERTY(barTintColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(tintColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(enablesReturnKeyAutomatically, BOOL)
RCT_EXPORT_VIEW_PROPERTY(barStyle, UIBarStyle)
RCT_EXPORT_VIEW_PROPERTY(searchBarStyle, UISearchBarStyle)
RCT_CUSTOM_VIEW_PROPERTY(hideBackground, BOOL, RNSearchBar)
{
    if ([RCTConvert BOOL:json]) {
        view.backgroundImage = [[UIImage alloc] init];
        view.backgroundColor = [UIColor clearColor];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(editable, BOOL, RNSearchBar)
{
    if ([RCTConvert BOOL:json]) {
        [view setUserInteractionEnabled: YES];
        view.alpha = 1;
    } else {
        [view setUserInteractionEnabled: NO];
        view.alpha = .75;
    }
}

RCT_CUSTOM_VIEW_PROPERTY(textFieldBackgroundColor, UIColor, RNSearchBar)
{
  if ([RCTConvert UIColor:json]) {
    // logic borrowed from http://stackoverflow.com/a/22266150/395989
    CGSize size = CGSizeMake(34, 34);
    // create context with transparent background
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);

    // Add a clip before drawing anything, in the shape of an rounded rect
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, 34, 34)
                                cornerRadius:5.0] addClip];
    [[RCTConvert UIColor:json]  setFill];

    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [view setSearchFieldBackgroundImage:image forState:UIControlStateNormal];
    [view setSearchTextPositionAdjustment:UIOffsetMake(8.0, 0.0)];
  }
}

//based on http://stackoverflow.com/questions/19048766/
RCT_CUSTOM_VIEW_PROPERTY(textColor, UIColor, RNSearchBar)
{
    if([RCTConvert UIColor:json]) {
       [[UITextField appearanceWhenContainedIn:[RNSearchBar class], nil] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[RCTConvert UIColor:json]}];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(searchImgInfo, NSDictionary, RNSearchBar)
{
    if ([RCTConvert NSDictionary:json]) {
        NSString *imgPath = [json objectForKey:@"img"];
        UIImage *image = [UIImage imageWithContentsOfFile:imgPath];
        
        //You should better define the size value, or the image will be draw in uncontrol size.
        NSDictionary *sizeDic = [json objectForKey:@"size"];
        if (sizeDic && [[json objectForKey:@"size"] objectForKey:@"width"] && [[json objectForKey:@"size"] objectForKey:@"height"]) {
            CGSize imgSize = CGSizeMake([[[json objectForKey:@"size"] objectForKey:@"width"] floatValue], [[[json objectForKey:@"size"] objectForKey:@"width"] floatValue]);
            CGImageRef imageRef = [image CGImage];
            CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
            CGImageRef ref = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, size.width, size.height));
            UIGraphicsBeginImageContextWithOptions(imgSize, NO, 0);
            CGContextRef con = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(con, 0, imgSize.height);
            CGContextScaleCTM(con, 1.0, -1.0);
            CGContextDrawImage(con, CGRectMake(0, 0, imgSize.width, imgSize.height), ref);
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
        }
        [view setImage:image forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    }
}

- (NSDictionary *)constantsToExport
{
  return @{
           @"ComponentHeight": @([self view].intrinsicContentSize.height),
           };
}

RCT_EXPORT_METHOD(blur:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:
     ^(__unused RCTUIManager *uiManager, NSDictionary *viewRegistry){
         RNSearchBar *searchBar = viewRegistry[reactTag];

         if ([searchBar isKindOfClass:[RNSearchBar class]]) {
             [searchBar endEditing:true];
         } else {
             RCTLogError(@"Cannot blur: %@ (tag #%@) is not RNSearchBar", searchBar, reactTag);
         }
     }];
}

RCT_EXPORT_METHOD(focus:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:
     ^(__unused RCTUIManager *uiManager, NSDictionary *viewRegistry){
         RNSearchBar *searchBar = viewRegistry[reactTag];

         if ([searchBar isKindOfClass:[RNSearchBar class]]) {
             [searchBar becomeFirstResponder];
         } else {
             RCTLogError(@"Cannot focus: %@ (tag #%@) is not RNSearchBar", searchBar, reactTag);
         }
     }];
}

RCT_EXPORT_METHOD(unFocus:(nonnull NSNumber *)reactTag)
{
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary *viewRegistry){
     RNSearchBar *searchBar = viewRegistry[reactTag];
     
     if ([searchBar isKindOfClass:[RNSearchBar class]]) {
       [searchBar resignFirstResponder];
     } else {
       RCTLogError(@"Cannot unFocus: %@ (tag #%@) is not RNSearchBar", searchBar, reactTag);
     }
   }];
}

@end
