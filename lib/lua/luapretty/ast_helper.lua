-------------------------------------------------------------------------------
-- LuaDocumentator2 - AST Helper
-- @release 2011/04/04 11:49:00, Viliam Kubis
-------------------------------------------------------------------------------

module("luapretty.ast_helper",package.seeall)

-------------------------------------------
-- Searches *direct* children nodes of the node "node", until it finds a node identified by key "key"
-- @param node current node to search in
-- @param key node name to search for amongst direct children of this node
-- @returns direct children node if found, otherwise nil
local function search(node,key)
	if(node==nil) then
		return nil;
	end
	for k,v in pairs(node) do
		if(type(v)=="table") then
			if(v['key']:lower()==key) then
				return v;
			end
		end
	end
	return nil;
end

-------------------------------------------
-- Extracts the corresponding function node from the given parse tree identified by the function's name
-- @param ast abstract or full parse tree as returned by the highlighter or formatter
-- @param functionname function name to search for, first matching function node is returned
-- @returns function node starting with "localfunction" or "globalfunction" entry or nil if not found
function getfunctionnode(ast,functionname)
	ast['key']=tostring(ast['key']);

	if(ast['key']:lower()=="globalfunction") then
		local funcname=search(search(search(ast,"funcname"),"name"),"id");
		if(funcname['str']==functionname) then
			return ast;
		end
	elseif(ast['key']:lower()=="localfunction") then
		local funcname=search(search(ast,"name"),"id");
		if(funcname['str']==functionname) then
			return ast;
		end
	end

	for k,v in pairs(ast) do
		if(type(v)=="table") then
			local ret=getfunctionnode(v,functionname);
			if(ret~=nil) then
				return ret;
			end
		end
	end
	return nil;
end

--------------------------------------------
-- Converts given METRICS abstract syntactic tree to HIGHLIGHTER compatible abstract syntactic tree.
-- @param tbl METRICS abstract syntactic tree to convert
-- @param new_tbl new HIGHLIGHTER compatible table to modify, or if nil, to create
-- @returns reference to created or modified compatible table
function metrics_to_highlighter(tbl,new_tbl)
	if(type(tbl)~="table") then
		return tbl;
	end

	new_tbl=new_tbl or {};
	
	local table_found=false;
	for k,v in ipairs(tbl.data) do 
		if(type(v)=="table") then 
			new_tbl[k]=metrics_to_highlighter(v);
			table_found=true;
		end
	end
	
	new_tbl['key']=(tbl['key']=="NEWLINE" and "SPACE" or tbl['key']);
	new_tbl['str']=tbl['text'];
	
	if(tbl['varid']) then
		new_tbl['css_extra']=" pp_js_varid pp_js_var"..tbl['varid'];
	end
	return new_tbl;
end
