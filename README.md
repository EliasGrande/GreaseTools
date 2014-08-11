
GreaseTools
===========

GreaseTools is a set of commands useful for dealing with Greasemonkey scripts.
Extract metadata, compress keeping metadata, convert an image into data-uri, etc.

Building
--------

	make

Installing
----------

	make install

Synopsis
--------

	greasetools [--help|--version]
	greasetools meta-block [-o outputfile] [inputfile]
	greasetools meta-key key [inputfile]
	greasetools compress [-o outputfile] [inputfile]
	greasetools install [-b browser] [inputfile]
	greasetools file-uri filepath
	greasetools data-uri [-f [+tabwidth,tabs,spaces,linewidth]] [inputfile]
	greasetools dist-name [-s suffix] [inputfile]
	greasetools yui [args...]
	greasetools yui-path [-e]
	greasetools yui-update
	greasetools clean-trash [-r] [directory]

Commands
--------

	mb | meta-block [-o outputfile] [inputfile]
		Print  out  metadata  block.  Returns error if no metadata block
		found.

	mk | meta-key key [inputfile]
		Print out every value of metadata key @key.   Prints  one  value
		per  line, ignoring  the  empty  ones.  Returns error if key not
		found or all its values are empty.

	c | compress [-o outputfile] [inputfile]
		Minimize input using yuicompressor, preserving metadata and  /*!
		comments.

	i | install [-b browser] [inputfile]
		Open  local  url  of  inputfile  in  browser, which triggers the
		installation of the script if greasemonkey  (or  equivalent)  is
		installed. If browser is not specified it defaults to firefox.

	fu | file-uri filepath
		Print out filepath transformed into file URI scheme.

		Output example: file:///fullpath/to/the/given/filepath

	du | data-uri [-f [+tabwidth,tabs,spaces,linewidth]] [inputfile]
		Print out inputfile transformed into data URI scheme, to include
		data  in-line  in web pages, mostly used for images. With the -f
		option (which stands for  format),  formats  the  output  as  an
		indented  JavaScript string. If -f is present but +format is not
		specified, it defaults to +0,0,4,80, that is an indentation of 4
		spaces and a line-width of 80 characters.

		Html usage example: <img alt="" src="DATA_URI_HERE" />
		Css usage example: background-image: url(DATA_URI_HERE);

	dn | dist-name [-s suffix] [inputfile]
		Print  out a dist filename using metadata @name and @version. If
		suffix is not specified, it defualts to '.user.js'.  For example  if
		@name is 'Cool Script' and @version is '1.2.1', it prints 'cool-
		script-1.2.1.user.js'.

	y | yui [args...]
		Just call yuicompressor with the given args and STDIN.

	yp | yui-path [-e]
		Print out the compressor pathname.  With the  -e  option  (which
		stands for escape) escapes the spaces with '\' (backslash).

	yu | yui-update
		Downloads the latest release of yuicompressor to the GreaseTools
		lib folder.

	ct | clean-trash [-r] [directory]
		Remove common OS trash (*~, thumbs.db, .DS_Store) from the given
		directory.   With  the  -r option searchs for these files recur‐
		sively in the directory tree.  If directory is not specified, it
		defaults to '.' (current working directory).

Notes
-----

	If no inputfile is specified, it defaults to STDIN (standard input).
	If no outputfile is specified, it defaults to STDOUT (standard output).

