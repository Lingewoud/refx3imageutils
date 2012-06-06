#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"
#import "trimalphaApp.h"

int main (int argc, char * const * argv)
{
    return DDCliAppRunWithClass([trimalphaApp class]);
}
