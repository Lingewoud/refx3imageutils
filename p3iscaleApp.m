//
//  p3iscale.m
//  PAS3 Image Utils
//
//  Created by Pim Snel on 08-06-12.
//  Copyright (c) 2012 Lingewoud b.v. All rights reserved.
//

#import "p3imglib.h"
#import "p3iscaleApp.h"

@implementation p3iscaleApp
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
           "  -w, --width <INT>             New width in pixels \n"
           "  -h, --height <INT>            New height in pixels \n"
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
        {@"height",    'h',    DDGetoptRequiredArgument},
        {@"width",     'w',    DDGetoptRequiredArgument},
        {@"verbose",   'v',    DDGetoptNoArgument},
        {@"version",    0,      DDGetoptNoArgument},
        //{@"help",       'h',    DDGetoptNoArgument},
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
        NSLog(@"height:%d, width:%d",_height,_width);    
    if (_in && _out)
    {
        ddprintf(@"in: %@, out: %@, verbosity: %d\n", _in, _out, _verbosity);
        
        //  fail if no file
        if (![[NSFileManager defaultManager] fileExistsAtPath:_in])
        {
            ddfprintf(stderr, @"%@: %@: No such file\n", DDCliApp, _in);
            return EX_NOINPUT;
        }
                
        NSLog(@"height:%d, width:%d",_height,_width);    
        

        //THE SCALING MAGIC
        CGImageRef myImage = [p3imglib MyCreateCGImageFromFile:_in];
        CGImageRef outImage = [p3imglib resizeCGImage:myImage toWidth:_width andHeight:_height];

        [p3imglib CGImageWriteToFile:outImage withPath:_out];

            
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







@end
