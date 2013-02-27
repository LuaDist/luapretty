#!/usr/bin/env lua
-------------------------------------------------------------------------------
-- LuaHighlighter
-- @release 2011/04/04 11:49:00, Viliam Kubis
-------------------------------------------------------------------------------

local highlighter=require("luapretty.highlighter");
local getopt=require("alt_getopt");
local debug=require("debug");

local long_opts = {
   force = "f",
   full    = "a",
   ["css-target"] = "x",
   css = "c",
   title="t",
   help="h"
}

local function process_text(text,with_headers,css_embedded_code,css_link,html_title)
	return highlighter.highlight_text(text,nil,with_headers,css_embedded_code,css_link,html_title);
end

local function usage_info(arg)
	print("\nUsage: "..arg[0]..
[[ <input file> [<output file>] [-f]

Arguments:
   <input file>		lua source file to highlight
   <output file>	target file to write highlighted code. If omitted,
			highlighted lua code is written to stdout. If target
			file alerady exists, no action will be taken and a
			warning message will be printed to stdout (unless the
			-f option is present).
   -f, --force		force rewriting target file if it exists
   -a, --full		output complete HTML markup with headers and formatted
			lua code in the body element. If not set, program will
			generate only one portion of the HTML markup (the
			highlighted code).
   -x, --css-target	copy the CSS file given by the -c option to the
			specified location. If both -c and -a options are set,
			the CSS code is both included in the final markup and
			copied to the location provided. If the target CSS file
			already exists, it is NOT overwritten unless the -f flag
			is in effect. If only the -a option is set (not -c), you
			can use this option to specify a link to external CSS
			file in the final markup (http addresses are accepted)
   -c, --css		use the given CSS style file. If the output mode is set
			to full HTML markup (-a option), the CSS code will be
			embedded directly in the generated markup. If the -x
			option is also set, the whole css style file will be
			copied to the location  given in the -x parameter. If
			neither the -x or -a parameters are set, this option has
			no effect.
   -t, --title		if running in full markup mode (-a flag is set), set the
			page's TITLE element to the provided string. If not set,
			title defaults to the stripped down filename of the lua
			source file without path information. If the -a flag is
			not set, this option has no effect.
]]);
end

--hlavna cast programu

if(#arg<1) then
	usage_info(arg,options);
	return nil
end

optarg,optind = alt_getopt.get_opts (arg, "fax:c:t:h", long_opts)

local css_file=optarg['c'];
local css_target=optarg['x'];
local html_title=optarg['t'];

if(optind<#arg+1 and not optarg['h']) then
	--spracovat subor
	local file,ie=io.open(arg[optind]);
	if(not file) then
		print("ERROR: cannot open file "..arg[optind]..": "..ie);
		return nil,ie
	end

	--inicializacia argumentov
	if(html_title==nil) then
		local myfile=debug.getinfo(1, "S").source:sub(2)
		local pos=myfile:find("/[^/]+$");
		myfile=myfile:sub(pos and pos or 1)
		html_title=myfile:sub(1);
	end

	--ziskat CSS kod, ak bol zadany
	local embedded_css_code=nil

	if(css_file and optarg['a']) then
		local file, err=io.open(css_file); --lokalna premenna
		if(not file) then
			error("ERROR: cannot open CSS stylesheet: "..err);
			return nil, err
		end
		embedded_css_code=file:read("*all");
		file:close();
	end

	--css target file copy
	if(css_file and css_target) then
		if(css_file~=css_target) then
			--nestaci, ale budiz
			local file, err=io.open(css_file); --lokalna premenna
			local file2, err2=io.open(css_target); --lokalna premenna
			if(not file) then
				error("ERROR: cannot open CSS stylesheet: "..err);
				return nil, err
			end
			if(file2 and not optarg['f']) then
				print("WARNING: target css file already exists, please use the -f switch to overwrite!");
				file:close();
				file2:close();
				return nil, "Target CSS file already exists!"
			end
			if(file2) then
				file2:close();
			end
			file2, err=io.open(css_target,"w+");
			if(not file2) then
				error("ERROR: cannot create target CSS file: "..err);
				return nil, err
			end
			file2:write(file:read("*all"));
			file:close();
			file2:close();
		end
	end

	--naformatovat text
	local output=process_text(file:read("*all"),optarg['a'],embedded_css_code,css_target and css_target or css_file,html_title);
	file:close()

	if(arg[optind+1]) then
		--ok, otvorit pre zapis + premazat alebo vytvorit
		file,ie=io.open(arg[optind+1]);
		if(file and not optarg['f']) then
			print("WARNING: target file "..arg[optind+1].." already exists, use the -f switch to overwrite!");
			file:close();
			return nil,"Target file already exists!"
		end
		--zapisat
		file,ie=io.open(arg[optind+1],"w+");
		if(not file) then
			print("ERROR: cannot create file: "..ie);
			return nil,ie
		end
		--zapis
		file:write(output);
		file:close();
		return true
	end
	--zapis na stdout
	print(output);
	return true
else
      usage_info(arg);
end

