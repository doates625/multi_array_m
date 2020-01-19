# multi_array_m
Matlab package for multi-dimensional arrays  
Written by Dan Oates (WPI Class of 2020)

### Description
This package contains classes for multi-dimensional arrays. The files in this
package are described below:

- Abstract : Superclass for multi-array objects
- Array : Class of data-holding multi-array
- Range : Class for mapping discrete to continuous subscripts
- LUT : Class for function lookup tables with interpolation
- PosFmt : Enumeration of position formats

The multi-array classes support three different position formats:

- Ind : Single-element indexing [i]
- Sub : Multi-dimensional subscript arrays [s1; s1; ... sn]
- Val : Continuous-valued mapping [Range and LUT only]

### Cloning and Submodules
Clone this repo as '+multi_array' and add the containing dir to the Matlab path.