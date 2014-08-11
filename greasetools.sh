#!/usr/bin/env bash

# The MIT License (MIT)
#
# Copyright (c) 2014 Elías Grande Cásedas <elias.grande@casedas.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

PACKAGE="greasetools"
VERSION="v2.0.0-alpha"
WEBSITE="github.com/EliasGrande/GreaseTools"

version()
{
	echo "$PACKAGE version $VERSION | $WEBSITE"
}

c62() {
	read is
	for i in $is; do
		# 48-57
		if [ $i -lt 10 ]
		then
			i=`expr $i + 48`
		# 65-90
		elif [ $i -lt 36 ]
		then
			i=`expr $i + '(' 65 - 10 ')'`
		# 97-122
		else
			i=`expr $i + '(' 97 - 36 ')'`
		fi
		printf \\$(printf '%03o' $i);
	done
	echo
}


uid()
{
	echo "obase=62; $RANDOM`date +%s%N`" | bc | c62
}

tmpdir="/tmp/$PACKAGE-`uid`"
mkdir "$tmpdir" || exit $?

cexit()
{
	local code="$1"

	rm -Rf "$tmpdir" 2>&1|:
	exit $code
}

error()
{
	local code=$?
	local msg="$1"
	while [ $# -gt 1 ]; do shift; msg="$msg $1"; done

	[ -n "$msg" ] && echo "$PACKAGE: $msg" >&2
	[ $code -eq 0 ] && code=1
	cexit $code
}

selfdir=`readlink -m "$0/.."` || error

help()
{
	local manfile="$selfdir/$PACKAGE.1"
	[ -f "$manfile" ] || manfile="$manfile.gz"

	man "$manfile"
}

ftest()
{
	local filepath="$1"

	[ -f "$filepath" ] || if [ -d "$filepath" ]; then
		error "expected «$filepath» to be a file but found a directory"
	else
		error "file «$filepath» not found"
	fi
}

dtest()
{
	local dirpath="$1"

	[ -d "$dirpath" ] || if [ -f "$dirpath" ]; then
		error "expected «$dirpath» to be a directory but found a file"
	else
		error "directory «$dirpath» not found"
	fi
}

ntest()
{
	local value="$1"
	local argname="$2"
	local context="$3"

	[ -n "$value" ] || error "$context: $argname is empty or not defined"
}

rtest()
{
	local value="$1"
	local regexp="$2"
	local argname="$3"
	local context="$4"

	ntest "$value" "$argname" "$context"
	echo "$value" | grep -qe "$regexp" || \
		error "$context: $argname is not valid"
}

otest()
{
	local filepath="$1"

	[ -d "$filepath" ] && \
		error "bad output file: «$filepath» is a directory"
	[ -d "`dirname "$filepath"`" ] || \
		error "bad output file: parent directory of «$filepath» not found"
}

meta_block()
{
	local inputfile="$1"
	local outputfile="$2"

	if [ -n "$inputfile" ]; then
		:
		ftest "$inputfile"
		cat "$inputfile" | meta_block "" "$2"
	else
		if [ -n "$outputfile" ]; then
			otest "$outputfile"
			local tmp="$tmpdir/meta_block"
			meta_block > "$tmp" || error
			mv -f "$tmp" "$outputfile" || error
		else
			sed -ne '/\/\/\s*\=\=UserScript\=\=/,$p' | tac | \
			sed -ne '/\/\/\s*\=\=\/UserScript\=\=/,$p' | tac | \
			grep -e '^.' || \
				error 'meta-block: metadata block not found.'
		fi
	fi
}

meta_key()
{
	local key="$1"
	local inputfile="$2"

	if [ -n "$inputfile" ]; then
		:
		ftest "$inputfile"
		cat "$inputfile" | meta_key "$key"
	else
		rtest "$key" '^[A-Za-z\-][A-Za-z\-]*$' "<key>" "meta-key"
		local ekey=`echo "$key" | sed -e 's#\-#\\-#g'`
		meta_block | \
			grep -e '^//\s*\@'"$ekey"'\s' | \
			sed -e 's#^//\s*\@'"$ekey"'\s*##' \
				-e 's#\s*$##' -e '/^$/d' | \
			grep -e '^.' || \
				error "meta-key: no value for key '@$key' found."
	fi
}

yui_path="$selfdir/yuicompressor.jar"

yui()
{
	[ -f "$yui_path" ] || \
	error "yui: no compressor found, try '$0 yui-update' to download it."

	java -jar "$yui_path" "$@"
}

yui_update_error()
{
	error "yuicompressor download failed, please download it manually and"\
	      "save it as '$yui_path'"
}

yui_update()
{
	local relurl="https://github.com/yui/yuicompressor/releases"
	local latest=`curl -I "$relurl/latest"` || yui_update_error
	latest=`echo "$latest" | \
		sed -ne 's/^\s*Location\:\s*\(\S.*\S\)\s*$/\1/p'`
	[ -n "$latest" ] || yui_update_error
	echo "$latest"
	local version=`echo "$latest" | grep -oe '[0-9]\(\.[0-9]\)*$'`
	[ -n "$version" ] || yui_update_error
	local url="$relurl/download/v$version/yuicompressor-$version.jar"
	local tmp="$tmpdir/compressor"
	wget "$url" -O "$tmp" || yui_update_error
	mv -fv "$tmp" "$yui_path" || yui_update_error
}

compress()
{
	local inputfile="$1"
	local outputfile="$2"

	if [ -n "$inputfile" ]; then
		:
		ftest "$inputfile"
		local tmp="$tmpdir/compress_output"
		meta_block "$inputfile" > "$tmp" || error
		yui --type js "$inputfile" >> "$tmp" || error
		if [ -n "$outputfile" ]; then
			otest "$outputfile"
			mv -f "$tmp" "$outputfile" || error
		else
			cat "$tmp"
		fi
	else
		inputfile="$tmpdir/compress_input"
		cat > "$inputfile"
		compress "$inputfile" "$outputfile"
	fi
}

clean_trash()
{
	local directory="$1"
	local recursive="$2"

	[ -n "$directory" ] || directory="."

	dtest "$directory"
	if [ -n "$recursive" ]; then
		find "$directory/" \
			-type f \
			-name "*~" -o \
			-name ".DS_Store" -o \
			-name "thumbs.db" \
			| xargs rm -f;
	else
		rm -f \
			"$directory/"*~ \
			"$directory/."*~ \
			"$directory/.DS_Store" \
			"$directory/thumbs.db"
	fi
}

file_uri()
{
	ntest "$1" "<filepath>" "file-uri"
	local fullpath=`readlink -m "$1"` || error
	echo "file://$fullpath"
}

install()
{
	local inputfile="$1"
	local browser="$2"

	if [ -z "$inputfile" ]; then
		inputfile="/tmp/`uid`.user.js"
		cat > "$inputfile"
		local rmdelay="sleep 120; rm -f '$inputfile'"
		sh -c "$rmdelay" &
		disown %1
		install "$inputfile" "$browser"
		cexit $?
	fi

	local file_uri="`file_uri "$inputfile"`"
	[ -n "$browser" ] || browser="firefox"
	if [ -n "`pidof "$browser"`" ]; then
		$browser "$file_uri" || error
		t1="$browser"
		t2="greasemonkey installation"
		sleep 0.5 || sleep 1
		xdotool windowactivate `xdotool search --class "$t1"` 2>&1|:
		xdotool windowactivate `xdotool search --name "$t2"` 2>&1|:
		wmctrl -a "$t1" 2>&1|:
		wmctrl -a "$t2" 2>&1|:
	else
		$browser "$file_uri" &
		disown %1
	fi
}

data_uri_format()
{
	local format="$1"

	local tabsize=4
	local tabcount=0
	local spcount=$tabsize
	local wrap_def=80
	local wrap=$wrap_def

	if [ -n "$format" ]; then
		rtest "$format" '^\+\([0-9][0-9]*,\)\{3\}[0-9][0-9]*$' \
			"<format>" "data-uri"
		format="` echo "$format" | sed -e 's/[^0-9]/ /g'`"
		tabsize=` echo "$format" | awk '{print $1}'`
		tabcount=`echo "$format" | awk '{print $2}'`
		spcount=` echo "$format" | awk '{print $3}'`
		wrap=`    echo "$format" | awk '{print $4}'`
		[ -z "$tabsize" ]  && tabsize=0
		[ -z "$tabcount" ] && tabcount=0
		[ -z "$spcount" ]  && spcount=0
		[ -z "$wrap" ]     && wrap=$wrap_def
	fi

	wrap=`expr $wrap - '(' $tabsize '*' $tabcount ')'`
	wrap=`expr $wrap - '(' $spcount + 3 ')'`
	[ $wrap -lt 1 ] && error "data-uri: <linewidth> is not valid"

	local indent=
	while [ $tabcount -gt 0 ]; do
		indent="$indent`echo -e '\t'`"
		tabcount=`expr $tabcount - 1`
	done
	while [ $spcount -gt 0 ]; do
		indent="$indent "
		spcount=`expr $spcount - 1`
	done

	local tmp="$tmpdir/data_uri_format"
	#sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\n\\n/g' |
	fold -w $wrap | \
	sed -e ':a' -e 'N' -e '$!ba' -e "s/\n/'+\n$indent'/g" > "$tmp"
	printf "$indent'"
	cat "$tmp"
	echo "';"
}

data_uri()
{
	local inputfile="$1"
	local do_format="$2"
	local format="$3"

	if [ -n "$inputfile" ]; then
		:
		ftest "$inputfile"
		local mime=`file -b --mime-type "$inputfile"` || error
		[ -n "$mime" ] || error "data-uri: unable to findout mime-type."
		local tmp="$tmpdir/data_uri_output"
		printf "data:$mime;base64," > "$tmp"
		base64 -w 0 "$inputfile" >> "$tmp" || error
		if [ -n "$do_format" ]; then
			cat "$tmp" | data_uri_format "$format"
		else
			cat "$tmp"
		fi
	else
		inputfile="$tmpdir/data_uri_input"
		cat > "$inputfile"
		data_uri "$inputfile"
	fi
}

dist_name()
{
	local inputfile="$1"
	local suffix="$2"
	[ "$#" -eq "1" ] && suffix=".user.js";

	local tmp="$tmpdir/dist_name_meta"
	meta_block "$inputfile" "$tmp"

	local name=`meta_key "name" "$tmp"` || error
	name="`\
		echo "$name" | \
		tr '[:upper:]' '[:lower:]' | \
		sed -e 's#^[^a-z0-9]*##' \
		    -e 's#[^a-z0-9]*$##' \
		    -e 's#[^a-z0-9]\+#-#g' \
	`"
	local version="`meta_key "version" "$tmp"`" || error
	version="`\
		echo "$version" | \
		tr '[:upper:]' '[:lower:]' | \
		sed -e 's#^[^a-z0-9\.]*##' \
		    -e 's#[^a-z0-9\.]*$##' \
		    -e 's#[^a-z0-9\.]\+#-#g' \
	`"
	echo "$name-$version$suffix"
}

param_count_error()
{
	error "$1: unexpected parameter count"
}

option_error()
{
	error "$2: unexpected option '$1'"
}

case "$1" in
--version|version|v)
	# --version
	version
	;;
--help|help|h)
	# --help
	help
	;;
meta-block|mb)
	# meta-block [-o <outputfile>] [<inputfile>]
	case $# in
	3|4)
		[ "$2" = "-o" ] || option_error "$2" "$1"
		ntest "$3" "<outputfile>" "$1 -o"
		meta_block "$4" "$3" || error;;
	2)
		meta_block "$2" || error;;
	1)
		meta_block || error;;
	*)
		param_count_error "$1";;
	esac
	;;
meta-key|mk)
	# meta-key <varname> [<inputfile>]
	[ $# -gt 3 ] && param_count_error "meta-key"
	meta_key "$2" "$3" || error
	;;
compress|c)
	# compress [-o <outputfile>] [<inputfile>]
	case $# in
	3|4)
		[ "$2" = "-o" ] || option_error "$2" "$1"
		ntest "$3" "<outputfile>" "$1 -o"
		compress "$4" "$3" || error;;
	2)
		compress "$2" || error;;
	1)
		compress || error;;
	*)
		param_count_error "$1";;
	esac
	;;
install|i)
	# install [-b <browser>] [<inputfile>]
	case $# in
	3|4)
		[ "$2" = "-b" ] || option_error "$2" "$1"
		ntest "$3" "<browser>" "$1 -o"
		install "$4" "$3" || error;;
	2)
		install "$2" || error;;
	1)
		install || error;;
	*)
		param_count_error "$1";;
	esac
	;;
file-uri|fu)
	# file-uri <filepath>
	file_uri "$2"
	;;
data-uri|du)
	# data-uri [-f [+tabsize,tabcount,spacecount,width]] [<inputfile>]
	case $# in
	4)
		[ "$2" = "-f" ] || option_error "$2" "$1"
		case "$3" in
		+*)
			data_uri "$4" - "$3" || error;;
		*)
			option_error "$3" "$1";;
		esac
		;;
	3)
		[ "$2" = "-f" ] || option_error "$2" "$1"
		case "$3" in
		+*)
			data_uri "" - "$3" || error;;
		*)
			data_uri "$3" - || error
			echo;;
		esac
		;;
	2)
		case "$2" in
		-f)
			data_uri "" - || error
			echo;;
		*)
			data_uri "$2" || error
			echo;;
		esac
		;;
			
	1)
		data_uri || error
		echo;;
	*)
		param_count_error "$1";;
	esac
	;;
dist-name|dn)
	# dist-name [-s <suffix>] [<inputfile>]
	case $# in
	3|4)
		[ "$2" = "-s" ] || option_error "$2" "$1"
		dist_name "$4" "$3" || error;;
	2)
		dist_name "$2" || error;;
	1)
		dist_name || error;;
	*)
		param_count_error "$1";;
	esac
	;;
yui|y)
	# yui
	shift
	yui "$@" || error
	;;
yui-path|yp)
	# yui-path [-e]
	[ $# -gt 2 ] && param_count_error "$1"
	if [ $# -eq 2 ]; then
		[ "$2" = "-e" ] || option_error "$2" "$1"
		echo "$yui_path" | sed -e 's/ /\\ /g'
	else
		echo "$yui_path"
	fi
	;;
yui-update|yu)
	# yui-update
	yui_update || error
	;;
clean-trash|ct)
	# clean-trash [-r] [<directory>]
	[ $# -gt 3 ] && param_count_error "$1"
	case "$2" in
		-r)
			clean_trash "$3" "$2" || error;;
		*)
			clean_trash "$2" || error;;
	esac
	;;
*)
	[ -n "$1" ] && error "'$1' is not a $PACKAGE command, see '$0 --help'"
	help && error
	;;
esac

cexit 0

