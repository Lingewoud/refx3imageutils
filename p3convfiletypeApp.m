//
//  p3iscale.m
//  PAS3 Image Utils
//
//  Created by Pim Snel on 08-06-12.
//  Copyright (c) 2012 Lingewoud b.v. All rights reserved.
//

#import "p3imglib.h"
#import "p3convfiletypeApp.h"

@implementation p3convfiletypeApp
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
           "  -t, --type <png/jpg/tif>      Output type: png/jpg/tif, default png\n"
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
        {@"type",      't',    DDGetoptRequiredArgument},
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
    
   ///NSLog("type: %@",_type);
    
    int repType;
    if ([_type isEqualToString: @"jpg"]){
        repType = NSJPEGFileType;
    }
    else if ([_type isEqualToString: @"tif"]){
        repType = NSTIFFFileType;
    }
    else {
        repType = NSPNGFileType;
    }
    
    //NSLog(@"height:%d, width:%d",_height,_width);    
    if (_in && _out)
    {
        //ddprintf(@"in: %@, out: %@, verbosity: %d\n", _in, _out, _verbosity);
        
        //  fail if no file
        if (![[NSFileManager defaultManager] fileExistsAtPath:_in])
        {
            ddfprintf(stderr, @"%@: %@: No such file\n", DDCliApp, _in);
            return EX_NOINPUT;
        }
        
       
        //THE CONVERTING MAGIC        
        NSImage *psimage = [[NSImage alloc] initWithContentsOfFile:_in];
        
        if (![psimage isValid]) {
            NSLog(@"Invalid Image");
            return EX_NOINPUT;
        }

        NSBitmapImageRep *bits = [[NSBitmapImageRep alloc] initWithData:[psimage TIFFRepresentation]];
		NSData *data = [bits representationUsingType:repType properties: nil];
		[data writeToFile:_out atomically:NO];
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
