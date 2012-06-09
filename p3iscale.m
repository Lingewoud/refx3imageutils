#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"
#import "p3iscaleApp.h"

int main (int argc, char * const * argv)
{
    return DDCliAppRunWithClass([p3iscaleApp class]);
}
