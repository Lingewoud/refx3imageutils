//
//  p3imglib.m
//  PAS3 Image Utils
//
//  Created by Pim Snel on 08-06-12.
//  Copyright (c) 2012 Lingewoud b.v. All rights reserved.
//

#import "p3imglib.h"
#import <QuartzCore/QuartzCore.h>

@implementation p3imglib

- (id) init;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    return self;
}

+(CGImageRef) MyCreateCGImageFromFile: (NSString *) path {
    // Get the URL for the pathname passed to the function.
    NSURL             *url = [NSURL fileURLWithPath:path];
    CGImageRef        myImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];
    
    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    // Create the dictionary
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    // Create an image source from the URL.
    myImageSource = CGImageSourceCreateWithURL((CFURLRef)url, myOptions);
    CFRelease(myOptions);
    // Make sure the image source exists before continuing
    if (myImageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    // Create an image from the first item in the image source.
    myImage = CGImageSourceCreateImageAtIndex(myImageSource, 0, NULL);
    
    CFRelease(myImageSource);
    // Make sure the image exists before continuing
    if (myImage == NULL){
        fprintf(stderr, "Image not created from image source.");
        return NULL;
    }
    
    return myImage;
}
+(void) CGImageWriteToFile: (CGImageRef) image withPath:(NSString *) path {
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    CFRelease(destination);
}

/*+(CGImageRef) epsToPng:
source,dest)
image = OSX::NSImage.alloc.initWithContentsOfFile(source)

if image.nil?
p "error eps does not exist or could not be opened:"+source
else
image.writePNG(dest) 
end
end
*/

@end
