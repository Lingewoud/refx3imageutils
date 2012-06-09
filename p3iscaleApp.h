//
//  p3iscale.h
//  PAS3 Image Utils
//
//  Created by Pim Snel on 08-06-12.
//  Copyright (c) 2012 Lingewoud b.v. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"

@interface p3iscaleApp  : NSObject <DDCliApplicationDelegate>
{
    NSString * _in;
    NSString * _out;
    int _verbosity;
    BOOL _version;
    BOOL _help;
}


@end
