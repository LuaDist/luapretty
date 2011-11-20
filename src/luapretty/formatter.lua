-------------------------------------------------------------------------------
-- LuaDocumentator2 - Formatter
-- @release 2011/04/04 11:49:00, Viliam Kubis
-------------------------------------------------------------------------------

module("luapretty.formatter", package.seeall)

local lpeg=require("lpeg")
local leg_parser=require("leg.parser")
local leg_grammar=require("leg.grammar")
local leg_scanner=require("leg.scanner")
local cosmo=require("cosmo")
local debug=require("debug")

-------------------------------------------
-- Prepares the needed grammar
-- @param tbl grammar table, every entry will be transofrmed into capturing pattern (lepg.C)
-- @returns nothing, modifies the grammar table directly
local function prepare_grammar(tbl)
	for key,value in pairs(tbl) do
		tbl[key]=lpeg.C(value)
	end
end

local function print_table(tbl)
	for key,value in pairs(tbl) do
		print(key," ",value)
		if(type(value)=="table") then 
			print_table(value)
		end
	end
end

-------------------------------------------
-- Assembles the given parse tree into final text output
-- @param tbl full parse tree as returned by lpeg.match
-- @returns clean formatted text output
local function assemble_table(tbl)
	local output=""
	local table_found=false
	if(templates[tbl['key']]) then
		return tbl['str']
	end
	for k,v in pairs(tbl) do
		if(type(v)=="table") then
			output=output..assemble_table(v)
			table_found=true
		end
	end
	if(table_found==false) then
		return tbl['str']
	end
	return output
end

-------------------------------------------
-- Strips trailing and ending whitespace characters
-- @param str string to trim
-- @returns trimmed string
function trim(str)
	return str:gsub("^%s*(.-)%s*$","%1");
end

-------------------------------------------
-- Strips only ending whitespace characters
-- @param str string to trim
-- @returns trimmed string
function trim_ending(str)
	return str:gsub("^(%s*.-)%s*$","%1");
end

-------------------------------------------
-- Prepares captures for the given grammar with respect to the formatting requirements set in the user template
-- @param grammar_tbl grammar table
-- @param captures_tbl captures table, function modifies this table by adding / changing every key present in 
-- the given grammar table and creating a capturing function for each key
local function prepare_captures(grammar_tbl,captures_tbl)
	for key,value in pairs(grammar_tbl) do
		captures_tbl[key]=function(str,...)
			if templates[key] then
				local template=nil
				if(type(templates[key])=="function") then
					template=templates[key](str,...)
				elseif(type(templates[key])=="number") then
					template=tostring(templates[key])
				else
					template=templates[key]
				end
				local values={original_content=str,content=assemble_table({...})}
				if(values['content']) then
					values['trimmed_content']=trim(values['content']);
				else
					values['trimmed_content']=trim(str); -- if assembled node has no children nodes (assemble_table==nil)
				end
				for k,v in ipairs({...}) do
					if(type(v)=="table") then
						local content=assemble_table(v);
						if(content:find("\n")) then -- discards operators, keywords etc.
							local _spaces=""
							for spaces in template:gmatch("\n(%s+)$"..v['key']:lower()) do -- will execute only once
								content=trim_ending(content:gsub("\n","\n"..spaces));
								_spaces=spaces;
							end
							if(#_spaces) then
								-- we replaced some spaces
								-- look for a multiline string, we cannot indent it's contents 
								local change=0; -- byte offset created by replacing the "replaced" string by it's original
								for a,b,c,d in content:gmatch("((['\"-]?)()%[%[.-\n.-%]%]())") do
									if(b=="") then
										-- only if the string is not encapsulated in quoted string or in a comment (could be for example "9"-[[8\n]]" but unlikely)
										content=content:sub(1,c-1-change)..a:gsub("\n".._spaces,"\n")..content:sub(d-change);
										change=change+(a:len()-a:gsub("\n".._spaces,"\n"):len());
									end
								end
							end
						end
						if(values[v['key']:lower()] and type(values[v['key']:lower()]~="table")) then
							-- multiple cosmo replacements, make a table out of it
							values[v['key']:lower()]={values[v['key']:lower()],content}
						elseif(values[v['key']:lower()]) then -- if it is already table
							table.insert(values[v['key']:lower()],content);
						else -- first assignment (string)
							values[v['key']:lower()]=content;
						end
					end
				end
				str=cosmo.fill(template,values);
			end	
			return {key=key,str=str,...}
		end
	end
end

-------------------------------------------
-- Main function in this module, formats given chunk of lua code according to cosmo templates / user functions present in the given template file
-- @param text chunk of valid lua code to format
-- @param template name of template file to use, defaults to "templates.lua" if nil is given
-- @usage searches for the given template file first in the calling script's directory, then in the current module's directory
-- @returns formatted text and parsed parse tree, or nil and error message in case of an error (template file cannot be found or loaded)
function format_text(text,template)
	-- load template!
	if(template==nil) then
--~ 		template="templates.lua"
		templates = require"luapretty.templates.default"
	else 
--~ 		local mydir=debug.getinfo(1, "S").source:sub(2)
--~ 		mydir=mydir:sub(1,mydir:find("/[^/]+$"))
		local template_text, errmsg=loadfile(template);
		if(not template_text) then
			-- try to find the template file in our directory
			template_text, errmsg=loadfile(template);
			if(not template_text) then
				return nil,"template file does not exist!"
			end
		end
		
		templates = template_text();	
	end
	
	local rules=leg_parser.rules
	
	rules=leg_grammar.apply({COMMENT=leg_scanner.COMMENT, SPACE=leg_scanner.SPACE},rules)
	-- CAPTURES!
	local captures_tbl={}
	
	prepare_grammar(rules)
	rules['IGNORED']=lpeg.C((lpeg.V'SPACE' + lpeg.V'COMMENT')^0)
	prepare_captures(rules,captures_tbl)

	local grammar_with_captures=leg_grammar.apply(rules,nil,captures_tbl)
	
	local result=lpeg.match(grammar_with_captures,text)
	return assemble_table(result), result
end

