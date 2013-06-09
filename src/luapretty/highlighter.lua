-------------------------------------------------------------------------------
-- LuaDocumentator2 - Highlighter
-- @release 2011/04/04 11:49:00, Viliam Kubis
-------------------------------------------------------------------------------

module("luapretty.highlighter", package.seeall);

local lpeg=require("lpeg");
local leg_parser=require("leg.parser");
local leg_grammar=require("leg.grammar");
local leg_scanner=require("leg.scanner");

-------------------------------------------
-- Prepares the needed grammar
-- @param tbl grammar table, every entry will be transofrmed into capturing pattern (lepg.C)
-- @returns nothing, modifies the grammar table directly
local function prepare_grammar(tbl)
	for key,value in pairs(tbl) do
		tbl[key]=lpeg.C(value);
	end
end

local function print_table(tbl)
	for key,value in pairs(tbl) do
		print(key," ",value);
		if(type(value)=="table") then 
			print_table(value);
		end
	end
end

-------------------------------------------
-- Prepares captures for the given grammar
-- @param grammar_tbl grammar table
-- @param captures_tbl captures table, function creates a simple capturing function for each key in the grammar table
local function prepare_captures(grammar_tbl,captures_tbl)
	for key,value in pairs(grammar_tbl) do
		captures_tbl[key]=function(str,...)
			return {key=key,str=str,...};
		end;
	end
end

-------------------------------------------
-- Contains CSS symbol aliases
-- @class table
-- @name symbol_aliases
local symbol_aliases={
	['1'] = "whole_code"
	, ['+'] = "plus"
	, ['-'] = "minus"
	, ['*'] = "asterisk"
	, ['/'] = "slash"
	, ['%'] = "percent"
	, ['^'] = "circumflex"
	, ['#'] = "hash"
	, ['=='] = "equal"
	, ['~='] = "not_equal"
	, ['<='] = "lte"
	, ['>='] = "gte"
	, ['<'] = "lt"
	, ['>'] = "gt"
	, ['='] = "euqals"
	, ['('] = "left_parentheses"
	, [')'] = "right_parentheses"
	, ['{'] = "left_curly_brackets"
	, ['}'] = "right_curly_brackets"
	, ['['] = "left_square_brackets"
	, [']'] = "right_square_brackets"
	, [';'] = "semicolon"
	, [':'] = "colon"
	, [''] = "empty"
	, ['.'] = "dot"
	, ['..'] = "dots"
	, ['...'] = "3dots"
	, [','] = "comma"
}

-------------------------------------------
-- Contains a list of all built in lua modules
-- @class table
-- @name lua_modules
local lua_modules={
	"coroutine",
	"debug",
	"io",
	"math",
	"os",
	"package",
	"string",
	"table"
}

-------------------------------------------
-- Contains a list of all built in lua functions
-- @class table
-- @name lua_functions
local lua_functions={
	"_G",
	"_VERSION",
	"assert",
	"collectgarbage",
	"dofile",
	"error",
	"getfenv",
	"getmetatable",
	"ipairs",
	"load",
	"loadfile",
	"loadstring",
	"module",
	"next",
	"pairs",
	"pcall",
	"print",
	"rawequal",
	"rawget",
	"rawset",
	"require",
	"select",
	"setfenv",
	"setmetatable",
	"tonumber",
	"tostring",
	"type",
	"unpack",
	"xpcall"
}

-------------------------------------------
-- Contains a list of all lua keywords
-- @class table
-- @name lua_keywords
local lua_keywords={'FALSE',
	'TRUE',
	'NIL',
	'AND',
	'NOT',
	'OR',
	'DO',
	'IF',
	'THEN',
	'ELSE',
	'ELSEIF',
	'END',
	'FOR',
	'IN',
	'UNTIL',
	'WHILE',
	'REPEAT',
	'BREAK',
	'LOCAL',
	'FUNCTION',
	'RETURN'
}

-------------------------------------------
-- Checks if the given table "t" contains value "val" [direct value, not recursive]
-- @param t table to check
-- @param val value to look for
-- @returns true if value is found, false otherwise
local function in_table(t,val)
	for _,v in ipairs(t) do	
		if(v==val) then
			return true
		end
	end
	return false
end

-------------------------------------------
-- Assembles extra css class names depending on the key and value pair of the given node in parse tree
-- @param key current node key (=tag)
-- @param value current node value
-- @returns extra css class names for lua functions and modules, or an empty string if not applicable
local function css_extra(key,value)
	if(key=="Exp" or key=="_PrefixExp") then
		if(type(value)=="string") then
			value=value:gsub("%(.+$","");
			local dot_pos=value:find("%.");
			if(dot_pos) then
				for k,v in ipairs(lua_modules) do
					if(value:sub(0,dot_pos-1)==v) then
						return " lua_module "..v;
					end
				end
			else
				--funkcia
				for k,v in ipairs(lua_functions) do
					if(value==v) then
						return " lua_function "..v:lower();
					end
				end
			end
		end
	end
	return "";
end

-------------------------------------------
-- Gets basic css class names applicable to every node in the parse tree
-- @param key key of the current node
-- @returns basic css class names
local function get_css_class(key)
	if(type(key)=="number") then
		key=tostring(key);
	end
	if(key:match("^%u+$")) then
		return (in_table(lua_keywords,key) and "keyword " or "").."upper_"..key:lower();
	elseif(key:match("^[a-zA-Z_]+$")) then
		return key:lower();
	elseif(key:match("^%d+$")) then
		return symbol_aliases[key];
	else
		return "symbol symbol_"..symbol_aliases[key];
	end
end

-------------------------------------------
-- Converts the given text into "safe html" form, e.g. the resulting text can be safely included in the HTML document
-- @param text text to check and convert special characters into HTML entities
-- @returns converted text
local function sh(text)
	if(type(text)~="string") then
		return tostring(text);
	end
	text=text:gsub("&","&amp;");
  	text=text:gsub("&#","&#38;&#35;");
	text=text:gsub("<","&lt;");
	text=text:gsub(">","&gt;");
	text=text:gsub("\"","&#34;");
	text=text:gsub("'","&#39;");
	return text;
end

local todoi = 0
local questioni=0
local bugi=0
local fixmei=0
local infoi = 0
local howi=0
-------------------------------------------
-- Assembles the given parse tree into final HTML output chunk
-- @param tbl full parse tree as returned by lpeg.match
-- @returns HTML output chunk (span's starting with <span class='whole_code'>) and clean output (text only)
-- @usage NOTE: the function is declared globally, it is safe to call the function with olny specific nodes of the parse tree that
-- we are interested in highlighting (instead of whole code)
function assemble_table(tbl)
	local output="";
	local output_clean="";
	local table_found=false;
	for k,v in ipairs(tbl) do --ipairs is sufficient, as lpeg parsed sub-nodes will have only numeric keys
		if(type(v)=="table") then --just to be sure
			local out, out_clean=assemble_table(v);
			output=output..out;
			output_clean=output_clean..out_clean;
			table_found=true;
		end
	end
	if(table_found==false) then
				if(get_css_class(tbl["key"]) == "upper_comment")then
					if(string.match(sh(tbl['str']),"^--[%s]*TODO" ))then
						todoi=todoi+1
						return "<span class='"..get_css_class(tbl['key']).. "_todo"..(tbl['css_extra'] and tbl['css_extra'] or "").."'><a name='TODO" ..todoi .. "'></a>" ..sh(tbl['str']).."</span>", tbl['str'];
					end
					if(string.match(sh(tbl['str']),"^--[%s]*bug" ))then
						bugi=bugi+1
						return "<span class='"..get_css_class(tbl['key']).. "_bug"..(tbl['css_extra'] and tbl['css_extra'] or "").."'><a name='bug" ..bugi .. "'></a>" ..sh(tbl['str']).."</span>", tbl['str'];
					end
					if(string.match(sh(tbl['str']),"^--[%s]*?" ))then
						questioni=questioni+1
						return "<span class='"..get_css_class(tbl['key']).. "_question"..(tbl['css_extra'] and tbl['css_extra'] or "").."'><a name='question" ..questioni .. "'></a>" ..sh(tbl['str']).."</span>", tbl['str'];
					end
					if(string.match(sh(tbl['str']),"^--[%s]*fixme" ))then
						fixmei=fixmei+1
						return "<span class='"..get_css_class(tbl['key']).. "_fixme"..(tbl['css_extra'] and tbl['css_extra'] or "").."'><a name='fixme" ..fixmei .. "'></a>" ..sh(tbl['str']).."</span>", tbl['str'];
					end
					if(string.match(sh(tbl['str']),"^--[%s]*info" ))then
						infoi=infoi+1
						return "<span class='"..get_css_class(tbl['key']).. "_info"..(tbl['css_extra'] and tbl['css_extra'] or "").."'><a name='info" ..infoi .. "'></a>" ..sh(tbl['str']).."</span>", tbl['str'];
					end
					if(string.match(sh(tbl['str']),"^--[%s]*how" ))then
						howi=howi+1
						return "<span class='"..get_css_class(tbl['key']).. "_how"..(tbl['css_extra'] and tbl['css_extra'] or "").."'><a name='how" ..howi .. "'></a>" ..sh(tbl['str']).."</span>", tbl['str'];
					end
				end
				-- print(,sh(tbl['str']))
		return "<span class='"..get_css_class(tbl['key'])..(tbl['css_extra'] and tbl['css_extra'] or "").."'>"..sh(tbl['str']).."</span>", tbl['str'];
	end
	return "<span class='"..get_css_class(tbl['key'])..css_extra(tbl['key'],output_clean)..(tbl['css_extra'] and tbl['css_extra'] or "").."'>"..output.."</span>", output_clean;
end

-------------------------------------------
-- Main function in this module, highlights given chunk of lua code, and is also capable of producing complete HTML page
-- with custom stylesheet, either embedded or statically linked + custom html title
-- @param text chunk of valid lua code to highlight
-- @param pt parse tree as returned by the formatter or any other compatible parse tree, if nil is given a new parse tree is constructed (default)
-- @param with_headers if not nil, returns complete html page conforming to XHTML 1.0 Transitional specification, charset is specified as utf-8
-- @param embedded_css_code if not nil, this string is printed inside the <style type='text/css'> element in the document's head element
-- @param css_link if not nil, this string is used as a "href" parameter in the <link rel='stylesheet' ... element
-- @param html_title HTML title of the resulting HTML page, only has meaning if with_headers is not nil. If html_title is nil, "Highlighted code" is used as the page's title
-- @returns highlighted text and parsed parse tree
function highlight_text(text,pt,with_headers,embedded_css_code,css_link,html_title) -- je mozne predat hotovy parse tree (jedine, co musi obsahovat, je kluc kazdej node)
	local rules=leg_parser.rules;
	todoi=0
	bugi=0
	questioni=0
	fixmei=0
	infoi=0
	howi=0

	local output="";
	
	if(pt==nil) then
		local captures_tbl={};
		
		rules=leg_grammar.apply({COMMENT=leg_scanner.COMMENT, SPACE=leg_scanner.SPACE},rules)
	
		prepare_grammar(rules);
		rules['IGNORED']=lpeg.C((lpeg.V'SPACE' + lpeg.V'COMMENT')^0)
		prepare_captures(rules,captures_tbl);

		local grammar_with_captures=leg_grammar.apply(rules,nil,captures_tbl);

		pt=lpeg.match(grammar_with_captures,text);
	end
	
	-- initialize parameters
	if(with_headers) then
		if(html_title==nil) then
			html_title="Highlighted code";
		end
		output=[[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="description" content="Highlighted code using Lua Highlighter" />
<meta name="Author" content="Viliam Kubis" />
<meta name="keywords" content="highlight, code" />
<meta name="robots" content="index,follow" />
<title>]]..sh(html_title)..[[</title>]];
		if(embedded_css_code) then
			output=output.."<style type='text/css'>\n"..embedded_css_code.."\n</style>";
		end
		if(css_link) then
			output=output.."<link rel='stylesheet' type='text/css' media='all' href='"..sh(css_link).."' />";
		end
		output=output..[[
</head>
<body>
]];
	end
	
	output=output.."<pre class='highlighted_code'>"..assemble_table(pt).."</pre>";
	
	if(with_headers) then
		output=output.."</body></html>";
	end
	return output, pt
end

