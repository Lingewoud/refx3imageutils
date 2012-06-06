#import <QuartzCore/QuartzCore.h>
#import "trimalphaApp.h"

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};


@implementation trimalphaApp

- (id) init;
{
    self = [super init];
    if (self == nil)
        return nil;
        
    return self;
}

- (void) setVerbose: (BOOL) verbose;
{
    if (verbose)
        _verbosity++;
    else if (_verbosity > 0)
        _verbosity--;
}


- (void) printUsage: (FILE *) stream;
{
    ddfprintf(stream, @"%@: Usage [OPTIONS] -i <input file> -o <output file\n", DDCliApp);
}

- (void) printHelp;
{
    [self printUsage: stdout];
    printf("\n"
           "  -i, --in <FILENAME>           Input image filename to trim alpha from\n"
           "  -o, --out <FILENAME>          Output image filename\n"
           "  -v, --verbose                 Increase verbosity\n"
           "      --version                 Display version and exit\n"
           "  -h, --help                    Display this help and exit\n"
           "\n"
           "This program trims alpha from image files.\n");
}

- (void) printVersion;
{
    ddprintf(@"%@ version %s\n", DDCliApp, CURRENT_MARKETING_VERSION);
}

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionsParser;
{
    DDGetoptOption optionTable[] = 
    {
        // Long         Short   Argument options
        {@"in",        'i',    DDGetoptRequiredArgument},
        {@"out",       'o',    DDGetoptRequiredArgument},
        {@"verbose",    'v',    DDGetoptNoArgument},
        {@"version",    0,      DDGetoptNoArgument},
        {@"help",       'h',    DDGetoptNoArgument},
        {nil,           0,      0},
    };
    [optionsParser addOptionsFromTable: optionTable];
}

- (CGImageRef) MyCreateCGImageFromFile: (NSString *) path
{
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

- (int) application: (DDCliApplication *) app
   runWithArguments: (NSArray *) arguments;
{
    if (_help)
    {
        [self printHelp];
        return EXIT_SUCCESS;
    }
    
    if (_version)
    {
        [self printVersion];
        return EXIT_SUCCESS;
    }
    
    if (_in && _out)
    {
        ddprintf(@"in: %@, out: %@, verbosity: %d\n", _in, _out, _verbosity);
    
        //  fail if no file
        if (![[NSFileManager defaultManager] fileExistsAtPath:_in])
        {
            ddfprintf(stderr, @"%@: %@: No such file\n", DDCliApp, _in);
            return EX_NOINPUT;
        }
        
        //[self detectAlpha1];
        [self detectAlphaTopBottom];
        [self detectAlphaLeftRight];

            
    
    }
    else {
        ddfprintf(stderr, @"%@: input file and or output file is missing\n", DDCliApp);
        [self printUsage: stderr];
        ddfprintf(stderr, @"Try `%@ --help' for more information.\n",
                  DDCliApp);
        return EX_USAGE;
    }
    

    return EXIT_SUCCESS;
}

-(void) detectAlphaLeftRight2 {

    //try opening input image
    CGImageRef myImage = [self MyCreateCGImageFromFile:_in];
    
    NSUInteger width = CGImageGetWidth(myImage);
    NSUInteger height = CGImageGetHeight(myImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    memset(rawData,0,height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef cgContextRef = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGContextSaveGState(cgContextRef);
    
    CGContextTranslateCTM( cgContextRef, width/2, height/2 );
    CGContextRotateCTM( cgContextRef, DegreesToRadians(90) );
    CGContextScaleCTM(cgContextRef, 1.0, -1.0);
    CGContextDrawImage(cgContextRef, CGRectMake(-width / 2, -height / 2, width, height), myImage);
    
    
    CGImageRef cgImageRotated = CGBitmapContextCreateImage(cgContextRef);    
    
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImageRotated)); 
    
    // Get image width, height. We'll use the entire image.
    int myImageWidth  = CGImageGetWidth(cgImageRotated);
    int myImageHeight = CGImageGetHeight(cgImageRotated);
    if(_verbosity) NSLog(@"rotated sizes, w:%d, h:%d",myImageWidth, myImageHeight);
    NSNumber *newRow = 0;
    
    const UInt32 *pixels = (const UInt32*)CFDataGetBytePtr(imageData);
    
    NSMutableArray *notAlphaCols = [NSMutableArray array];
    
    for (int j = 0; j < (myImageHeight * myImageWidth); j++)
    {   
        newRow = [NSNumber numberWithInt: j/myImageWidth];
        //        newRow = j/myImageWidth;
        if (pixels[j] & 0xff000000)
        {
            [notAlphaCols addObject:newRow];
            if(_verbosity) NSLog(@"this is NOT a transparent pixel");
            
        }
        else
        {            
            if(_verbosity) NSLog(@"transparent pixel!");                        
        }
    }
    
    NSSet *_tmpSet = [[NSSet alloc] initWithArray: notAlphaCols];
    notAlphaCols = [[_tmpSet allObjects] mutableCopy];
    
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [notAlphaCols sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
    
     NSLog(@"notAlphaCols %@", notAlphaCols);

    
}

-(void) detectAlphaLeftRight {
    
    //try opening input image
    CGImageRef image = [self MyCreateCGImageFromFile:_in];
    
    CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));//draw at origin; translation will take care of movement
    //CGRect imageRect = CGRectMake(0, 0, CGImageGetHeight(image), CGImageGetWidth(image));//draw at origin; translation will take care of movement
    
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger height = CGImageGetHeight(image);
    CGFloat targetWidth = height;
    CGFloat targetHeight = width;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
//    CGContextRef context = CGBitmapContextCreate(NULL,targetWidth,targetHeight, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), colorSpace, kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Big);
    CGContextRef context = CGBitmapContextCreate(NULL,targetWidth,targetHeight, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), colorSpace, kCGImageAlphaPremultipliedLast);
    //    CGContextRef context = CGBitmapContextCreate(NULL,width,height, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), colorSpace, kCGImageAlphaPremultipliedLast);
    //CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    
    //CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //CGContextSaveGState(context);
    
    
    //METHODE 1
    //CGContextTranslateCTM (context, 100.0, 100.0);//Quartz origin is in the lower left corner
    //CGContextScaleCTM (context, 1.0, 1.0);
    //CGContextRotateCTM (context, 90*M_PI/180 );//convert to radians
    
    
    //METHODE 2

    CGContextRotateCTM(context, DegreesToRadians(90));
    CGContextTranslateCTM(context,0, -targetWidth);
    //CGContextScaleCTM(context, -1.0, 1.0);
    //CGContextScaleCTM (context, 1.0, 1.0);
   
    CGContextDrawImage(context, imageRect, image);//draw the bitmap (image) to the context in the specified rectangle
    //CGContextSaveGState(context);

    //CFRelease(imageSource);
    CFRelease(image);
    
    CGImageRef cgImageRotated = CGBitmapContextCreateImage(context);    
    
    [self CGImageWriteToFile:cgImageRotated withPath:@"/Users/pim/Desktop/testrotated.png"];

    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImageRotated)); 
    
    // Get image width, height. We'll use the entire image.
    int myImageWidth  = CGImageGetWidth(cgImageRotated);
    int myImageHeight = CGImageGetHeight(cgImageRotated);
     if(_verbosity) NSLog(@"rotated sizes, w:%d, h:%d",myImageWidth, myImageHeight);
    //NSNumber *currentRow = 0;
    NSNumber *newRow = 0;
    
    const UInt32 *pixels = (const UInt32*)CFDataGetBytePtr(imageData);
    
    NSMutableArray *notAlphaCols = [NSMutableArray array];
    
    for (int j = 0; j < (myImageHeight * myImageWidth); j++)
    {   
        newRow = [NSNumber numberWithInt: j/myImageWidth];
        //        newRow = j/myImageWidth;
        if (pixels[j] & 0xff000000)
        {
            [notAlphaCols addObject:newRow];
            //if(currentRow < newRow) [notAlphaRows addObject:currentRow];
            //break;
             if(_verbosity) NSLog(@"this is NOT a transparent pixel:%i %@",j,newRow);
            
        }
        else
        {            
             if(_verbosity) NSLog(@"transparent pixel!%i %@",j,newRow);                        
        }
        
        //currentRow = newRow;        
    }
    
    NSSet *_tmpSet = [[NSSet alloc] initWithArray: notAlphaCols];
    notAlphaCols = [[_tmpSet allObjects] mutableCopy];
    
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [notAlphaCols sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
    
     NSLog(@"notAlphaCols %@", notAlphaCols);
    
    
}

-(void) CGImageWriteToFile: (CGImageRef) image withPath:(NSString *) path {
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
         if(_verbosity) NSLog(@"Failed to write image to %@", path);
    }
    CFRelease(destination);
}
/*

NSString *path = [[NSBundle mainBundle] pathForResource:@"frog1" ofType:@"png"];
NSURL *imageURL = [NSURL fileURLWithPath:path];//this will cause an error if the image doesn't exist at the path specifed
CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageURL, NULL);//cast url to CF version



CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL ); 
CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));//draw at origin; translation will take care of movement


CGContextTranslateCTM (context, 100.0, 100.0);//Quartz origin is in the lower left corner
CGContextScaleCTM (context, 1.0, 1.0);
CGContextRotateCTM (context, 90*M_PI/180 );//convert to radians

CGContextDrawImage(context, imageRect, image);//draw the bitmap (image) to the context in the specified rectangle
CFRelease(imageSource);
CFRelease(image);
*/

-(void) detectAlphaTopBottom {
    //try opening input image
    CGImageRef myImage = [self MyCreateCGImageFromFile:_in];
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(myImage)); 
    // Get image width, height. We'll use the entire image.
    int myImageWidth  = CGImageGetWidth(myImage);
    int myImageHeight = CGImageGetHeight(myImage);
     if(_verbosity) NSLog(@"sizes, w:%d, h:%d",myImageWidth, myImageHeight);

    //NSNumber *currentRow = 0;
    NSNumber *newRow = 0;
    
    const UInt32 *pixels = (const UInt32*)CFDataGetBytePtr(imageData);

    NSMutableArray *notAlphaRows = [NSMutableArray array];
    
    for (int j = 0; j < (myImageHeight * myImageWidth); j++)
    {   
        newRow = [NSNumber numberWithInt: j/myImageWidth];
//        newRow = j/myImageWidth;
        if (pixels[j] & 0xff000000)
        {
            [notAlphaRows addObject:newRow];
            //if(currentRow < newRow) [notAlphaRows addObject:currentRow];
            //break;

           //NSLog(@"this is NOT a transparent pixel");
            
        }
        else
        {            
            //NSLog(@"transparent pixel!");                        
        }
        
        //currentRow = newRow;        
    }
    
    NSSet *_tmpSet = [[NSSet alloc] initWithArray: notAlphaRows];
    notAlphaRows = [[_tmpSet allObjects] mutableCopy];
    
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [notAlphaRows sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];

     NSLog(@"nonAlphaRows %@", notAlphaRows);
}

/*
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees 
{   
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    [rotatedViewBox release];
    
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
*/

-(void) detectAlpha1 {
    //try opening input image
    CGImageRef myImage = [self MyCreateCGImageFromFile:_in];
    // Get image width, height. We'll use the entire image.
    int myImageWidth  = CGImageGetWidth(myImage);
    int myImageHeight = CGImageGetHeight(myImage);
    
    CGRect origRect = CGRectMake(0,0,myImageWidth,myImageHeight);
    CGRect outBox = origRect;
    
    if(_verbosity) NSLog(@"old height:%f",outBox.size.height);
    
    float theCol;
    
    // Cut off any empty rows at the bottom:
    for( int y = 0; y < origRect.size.height; y++ )
    {
        for( int x = 0; x < origRect.size.width; x++ )
        {
            theCol = [self alphaInImage:myImage AtPixel:CGPointMake( x, y )];
            if( theCol > 0.01 )
            {
                 if(_verbosity) NSLog(@"Breaking:1");
                
                break;
            }
        }
        if( theCol > 0.01 ) {
             if(_verbosity) NSLog(@"Breaking:2");
            break;
        }
        
        outBox.origin.y += 1;
        outBox.size.height -= 1;
    }      
     if(_verbosity) NSLog(@"new height:%f",outBox.size.height);
    
    
    //  fail if no image file
    
    //do magic
    
    //write output file
    //  fail if no output path
    
}

- (float) alphaInImage: (CGImageRef) cgImage AtPixel:(CGPoint)point {

    int myImageWidth  = CGImageGetWidth(cgImage);
    int myImageHeight = CGImageGetHeight(cgImage);
    
    // Cancel if point is outside image coordinates
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, myImageWidth, myImageHeight), point)) {
         if(_verbosity) NSLog(@"out of bounds:");
        return 1.0;
    }
    
    // Create a 1x1 pixel byte array and bitmap context to draw the pixel into.
    // Reference: http://stackoverflow.com/questions/1042830/retrieving-a-pixel-alpha-value-for-a-uiimage
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    NSUInteger width = CGImageGetWidth(cgImage);
    NSUInteger height = CGImageGetHeight(cgImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData, 
                                                 1,
                                                 1,
                                                 bitsPerComponent, 
                                                 bytesPerRow, 
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, -pointY);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    
    return alpha;
}



@end
