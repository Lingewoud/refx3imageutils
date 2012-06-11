#import <QuartzCore/QuartzCore.h>
#import "trimalphaApp.h"
#import "p3imglib.h"

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
        
        //THE DETECTING AND CROPPING MAGIC
        CGImageRef myImage = [p3imglib MyCreateCGImageFromFile:_in];
        NSArray* vertOffsets = [NSArray arrayWithArray:[self detectAlphaTopBottom:myImage]];
        NSArray* horOffsets = [NSArray arrayWithArray:[self detectAlphaLeftRight:myImage]];


        CGRect croppingRect = CGRectMake([[horOffsets objectAtIndex:0] floatValue], 
                                         [[vertOffsets objectAtIndex:0] floatValue], 
                                         [[horOffsets objectAtIndex:1] floatValue], 
                                         [[vertOffsets objectAtIndex:1] floatValue]);
      
        [self cropImage:myImage withRect:croppingRect saveTo:_out];
    
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

-(NSArray*) detectAlphaTopBottom:(CGImageRef)myImage2 {
    //try opening input image
    CGImageRef myImage = [p3imglib MyCreateCGImageFromFile:_in];
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(myImage)); 
    // Get image width, height. We'll use the entire image.
    int myImageWidth  = CGImageGetWidth(myImage);
    int myImageHeight = CGImageGetHeight(myImage);
    if(_verbosity) NSLog(@"sizes, w:%d, h:%d",myImageWidth, myImageHeight);
    
    NSNumber *newRow = 0;
    
    const UInt32 *pixels = (const UInt32*)CFDataGetBytePtr(imageData);
    
    NSMutableArray *notAlphaRows = [NSMutableArray array];
    
    for (int j = 0; j < (myImageHeight * myImageWidth); j++)
    {   
        newRow = [NSNumber numberWithInt: j/myImageWidth];
        if (pixels[j] & 0xff000000)
        {
            [notAlphaRows addObject:newRow];
            
            if(_verbosity) NSLog(@"this is NOT a transparent pixel");
            
        }
        else
        {            
            if(_verbosity) NSLog(@"transparent pixel!");                        
        }
    }
    
    NSSet *_tmpSet = [[NSSet alloc] initWithArray: notAlphaRows];
    notAlphaRows = [[_tmpSet allObjects] mutableCopy];
    
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [notAlphaRows sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
    
    NSMutableArray *verticalRectVals = [NSMutableArray array];
    
    int topOffset = [[notAlphaRows objectAtIndex:0] intValue];
    
    int bottomOffset = myImageHeight - [[notAlphaRows lastObject] intValue] - 1;
    int height = myImageHeight - topOffset - bottomOffset; 
    
    [verticalRectVals addObject:[NSNumber numberWithInt:topOffset]];
    [verticalRectVals addObject:[NSNumber numberWithInt:height]];
    if(_verbosity) NSLog(@"nonAlphaRows %@", notAlphaRows);
    if(_verbosity) NSLog(@"verticalRectVals %@", verticalRectVals);
    
    return verticalRectVals;
}

-(NSArray*) detectAlphaLeftRight:(CGImageRef)image2 {

    CGImageRef image = [p3imglib MyCreateCGImageFromFile:_in];
    CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));//draw at origin; translation will take care of movement
    
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger height = CGImageGetHeight(image);
    CGFloat targetWidth = height;
    CGFloat targetHeight = width;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 targetWidth,
                                                 targetHeight, 
                                                 CGImageGetBitsPerComponent(image), 
                                                 CGImageGetBytesPerRow(image), 
                                                 colorSpace, 
                                                 kCGImageAlphaPremultipliedLast);
    
    CGContextRotateCTM(context, DegreesToRadians(-90));
    CGContextTranslateCTM(context,-targetHeight, 0);
    CGContextDrawImage(context, imageRect, image);

    CFRelease(image);
    
    CGImageRef cgImageRotated = CGBitmapContextCreateImage(context);    
    //FIXME SAVE STEP BETWEEN IS NEEDED BUT WHY?
    [p3imglib CGImageWriteToFile:cgImageRotated withPath:@"/tmp/p3trimalpharotated.png"];
    
    CGImageRef cgImageRotated2 = [p3imglib MyCreateCGImageFromFile:@"/tmp/p3trimalpharotated.png"];
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImageRotated2)); 
    
    // Get image width, height. We'll use the entire image.
    int myImageWidth  = CGImageGetWidth(cgImageRotated2);
    int myImageHeight = CGImageGetHeight(cgImageRotated2);
    
    NSLog(@"rotated sizes, w:%d, h:%d",myImageWidth, myImageHeight);
    
    NSNumber *newRow = 0;
    
    const UInt32 *pixels2 = (const UInt32*)CFDataGetBytePtr(imageData);
    
    NSMutableArray *notAlphaCols = [NSMutableArray array];
    
    for (int j = 0; j < (myImageHeight * myImageWidth); j++)
    {   
        newRow = [NSNumber numberWithInt: j/myImageWidth];
        if (pixels2[j] & 0xff000000)
        {
            [notAlphaCols addObject:newRow];

            if(_verbosity) NSLog(@"this is NOT a transparent pixel:%i %@",j,newRow);
            
        }
        else
        {            
             if(_verbosity) NSLog(@"transparent pixel!%i %@",j,newRow);                        
        }
    }
    
    NSSet *_tmpSet = [[NSSet alloc] initWithArray: notAlphaCols];
    notAlphaCols = [[_tmpSet allObjects] mutableCopy];
    
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [notAlphaCols sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
    
    NSMutableArray *horizontalRectVals = [NSMutableArray array];
    
    int topOffset = [[notAlphaCols objectAtIndex:0] intValue];
    
    int bottomOffset = myImageHeight - [[notAlphaCols lastObject] intValue] - 1;
    int newheight = width - topOffset - bottomOffset; 

    
    [horizontalRectVals addObject:[NSNumber numberWithInt:topOffset]];
    [horizontalRectVals addObject:[NSNumber numberWithInt:newheight]];
    if(_verbosity) NSLog(@"nonAlphaCols %@", notAlphaCols);    
    NSLog(@"horizontalRectVals %@", horizontalRectVals);
    
    return horizontalRectVals;
}

-(void) cropImage:(CGImageRef)image withRect:(CGRect)cropRect saveTo:(NSString*)path{
    
    CGImageRef cgImageCropped = CGImageCreateWithImageInRect(image, cropRect);

    [p3imglib CGImageWriteToFile:cgImageCropped withPath:path];
}


@end
