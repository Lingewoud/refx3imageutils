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

@end