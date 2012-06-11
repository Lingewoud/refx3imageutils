PAS3 Image Utilities
===============

Cli utilities for PAS3

These cli programs are developed for PAS3 and REFx. They are a replacement for command line tools we used like ImageMagick and GhostScript. PAS3 Image Utilities are written in Objective C and heavily use the Cocoa framework.

Utilities:

* **p3trimalpha**: 		trim whitespace from image (ALPHA VERSION)
* **p3scale**:			scale image (ALPHA VERSION)
* **pdf2png**:			convert pdf to png (PLANNED)
* **eps2png**:			convert eps to png (??)
* **tiff2png**:			convert tiff to png (??)
* **p3imgtool**:		wrapper for above (PLANNED)

---------
###p3trimalpha

trimalpha strips all transparant margins from an image. Replaces the ImageMagick command:

`./convert -alpha Set -background transparent  -trim <source file> <destination file>`
	
Usage:

`./p3trimalpha -i <source file> -o <destination file>`

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
	
	
###p3scale

p3scale scales an image.
	
Usage:

`./p3scale -i <source file> -o <destination file> -w<width pixels> -h <height pixels>`

TODO

* Add list of supported filetypes
* Create as library for pas3imagetool
* More documentation
* Add options:
	* replace original file
	* Destination filetype