PAS3 Image Utilities
===============

Cli utilities for PAS3

These cli programs are developed for PAS3 and REFx. They are a replacement for command line tools we used like ImageMagick and GhostScript. PAS3 Image Utilities are written in Objective C and heavily use the Cocoa framework.

Utilities:

* **trimalpha**: 		trim whitespace from image (ALPHA VERSION)
* **imgscale**:			scale image (PLANNED)
* **pdf2png**:			convert pdf to png (PLANNED)
* **eps2png**:			convert eps to png (??)
* **tiff2png**:			convert eps to png (??)
* **pas3imagetool**:	wrapper for above (PLANNED)

trimalpha
---------
trimalpha strips all transparant margins from an image. Replaces the ImageMagick command:

`./convert -alpha Set -background transparent  -trim <source file> <destination file>`
	
Usage:

`./trimalpha -i <source file> -o <destination file>`

TODO

* Code Cleanup/Merge methods
* Fix strange requirement to save before detect left/right
* Improve perfomance by improving alpha rows detection mechanism
* Add list of supported filetypes
* Create as library for pas3imagetool
* More documentation
* Add options:
	* replace original file
	* Destination filetype