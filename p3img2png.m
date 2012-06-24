#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"
#import "p3img2pngApp.h"

int main (int argc, char * const * argv)
{
    return DDCliAppRunWithClass([p3img2pngApp class]);
}
