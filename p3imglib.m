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

/*
 +(CGImageRef) scaleImageKeepAscectRatio: (CGImageRef)image maxPixelWidth:(int)w maxPixelHeight:(int)h  {
    NSUInteger orgWidth = CGImageGetWidth(image);
    NSUInteger orgHeight = CGImageGetHeight(image);
    float new_y= (orgHeight-h);

    
    CGRect croprect = CGRectMake(0,new_y,w,h);
    
        
    CGImageRef sizedImage = [image imageByCroppingToRect:croprect];
    return sizedImage;
}
 */

+ (CGImageRef)resizeCGImage:(CGImageRef)image toWidth:(int)width andHeight:(int)height {

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);

    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height, 
                                                 CGImageGetBitsPerComponent(image), 
                                                 CGImageGetBytesPerRow(image), 
                                                 colorSpace, 
                                                 kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if(context == NULL)
        return nil;
    
    // draw image to context (resizing it)
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // extract resulting image from context
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return imgRef;
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

/*
 def cropBitmap105(source,dest,w,h)
 image = OSX::CIImage.alloc.initWithContentsOfURL(OSX::NSURL.fileURLWithPath(source))
 if image.nil?
 p "error eps does not exist or could not be opened:"+source
 else
 original_size = image.extent.size
 
 new_y= (original_size.height-h)
 
 croprect = OSX::CGRectMake(0,new_y,w,h)
 imageCropped = image.imageByCroppingToRect(croprect)
 
 format = OSX::NSPNGFileType
 properties = nil
 
 bitmapRep = OSX::NSBitmapImageRep.alloc.initWithCIImage(imageCropped)
 blob = bitmapRep.representationUsingType_properties(format, properties)
 blob.writeToFile_atomically(dest, false)
 end
 end*/

@end
