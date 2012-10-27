#!/usr/bin/env lua
-------------------------------------------------------------------------------
-- LuaFormatter
-- @release 2011/04/04 11:49:00, Viliam Kubis
-------------------------------------------------------------------------------

local formatter=require("luapretty.formatter");
local getopt=require("alt_getopt");

local long_opts = {
	template = "t",
	force    = "f",
	help = "h"
}

local function process_text(text,template)
	local result,err=formatter.format_text(text,template);
	if(not result) then
		error("ERROR: "..err);
	end
	return result
end

local subor=nil; --template file

local function usage_info(args)
	print("\nUsage: "..arg[0]..
[[ <input file> [<output file>] [-t <template file>] [-f]

Arguments:
   <input file>		lua source file to reformat
   <output file>	target file to write reformatted code. If omitted,
				reformatted lua code is written to stdout. If target
				file alerady exists, no action will be taken and a
				warning message will be printed to stdout (unless the
				-f option is present).
   -t, --template	use the given template, defaults to "templates.lua"
   -f, --force		force rewriting target file if it exists
   ]]);
end

--hlavna cast programu

if(#arg<1) then
	usage_info(arg);
	return nil
end

optarg,optind = alt_getopt.get_opts(arg,"t:fh",long_opts);

if(optind<#arg+1 and not optarg['h']) then
	--spracovat subor
	local file,ie=io.open(arg[optind]);
	if(not file) then
		print("ERROR: cannot open file "..arg[optind]..": "..ie);
		return nil,ie
	end

	--naformatovat text
	local output=process_text(file:read("*all"),optarg['t']);
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

