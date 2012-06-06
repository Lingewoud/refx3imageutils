#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"

@interface trimalphaApp : NSObject <DDCliApplicationDelegate>
{
    NSString * _in;
    NSString * _out;
    int _verbosity;
    BOOL _version;
    BOOL _help;
}


- (CGImageRef) MyCreateCGImageFromFile: (NSString *) path;
//-(void) CGImageWriteToFile: (CGImageRef) image :(NSString *) path;
-(void) CGImageWriteToFile: (CGImageRef) image withPath:(NSString *) path;



@end