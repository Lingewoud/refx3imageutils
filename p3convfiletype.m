#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"
#import "p3convfiletypeApp.h"

int main (int argc, char * const * argv)
{
    return DDCliAppRunWithClass([p3convfiletypeApp class]);
}
