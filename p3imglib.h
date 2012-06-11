//
//  p3imglib.h
//  PAS3 Image Utils
//
//  Created by Pim Snel on 08-06-12.
//  Copyright (c) 2012 Lingewoud b.v. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface p3imglib : NSObject

+ (CGImageRef) MyCreateCGImageFromFile: (NSString *) path;
+ (void) CGImageWriteToFile: (CGImageRef) image withPath:(NSString *) path;
+ (CGImageRef)resizeCGImage:(CGImageRef)image toWidth:(int)width andHeight:(int)height;
@end
