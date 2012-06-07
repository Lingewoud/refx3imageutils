PAS3 Image Utilities
===============

Cli utilities for PAS3

These cli programs are developed for PAS3 and REFx. They are a replacement for command line tools we used like ImageMagick and GhostScript. PAS3 Image Utilities are written in Objective C and heavily use the Cocoa framework.

Utilities:

**trimalpha**

trimalpha strips all transparant margins from an image. Replaces the ImageMagick command:

`./convert -alpha Set -background transparent  -trim <source file> <destination file>`
	
Usage:

`./trimalpha -i <source file> -o <destination file>`

