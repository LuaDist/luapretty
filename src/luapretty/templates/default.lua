return  {
	IGNORED = nil
	, EPSILON = nil
	, EOF = nil
	, BOF = nil
	, NUMBER = nil
	, ID = nil
	, STRING = nil
	, Name = nil

-- CHUNKS
	, [1] = nil
	, CHUNK = nil
	, Chunk = nil
	, Block = nil

-- STATEMENTS
	, Stat = nil
	, Assign = nil
	, Do = nil
	, While =  nil
	, Repeat = nil
	, If = nil
	, NumericFor = nil
	, GenericFor = nil
	, GlobalFunction = nil
	, LocalFunction = nil
	, LocalAssign = nil
	, LastStat = nil	

-- LISTS
	, VarList = nil
	, NameList = nil
	, ExpList = nil

-- EXPRESSIONS
	, Exp = nil
	, _SimpleExp = nil
	, _PrefixExp = nil
	, _PrefixExpParens = nil
	, _PrefixExpSquare = nil
	, _PrefixExpDot = nil
	, _PrefixExpArgs = nil
	, _PrefixExpColon = nil

	-- solving the left recursion problem
	, Var = nil
	, FunctionCall = nil

-- FUNCTIONS
	, Function = nil
	, FuncBody = nil
	, FuncName = nil
	, Args =  nil
	, ParList = nil
-- TABLES
	, TableConstructor = nil
	, FieldList = nil
	, Field = nil
	, _FieldSquare = nil
	, _FieldID = nil
	, _FieldExp = nil
	, FieldSep = nil

-- OPERATORS
	, BinOp = nil
	, UnOp = nil

-- COMMENTS AND WHITESPACE
	, COMMENT = nil
	, SPACE = nil

-- KEYWORDS
	, ['FALSE'] = nil
	, ['TRUE'] = nil
	, ['NIL'] = nil

	, ['AND'] = nil
	, ['NOT'] = nil
	, ['OR'] = nil

	, ['DO'] = nil
	, ['IF'] = nil
	, ['THEN'] = nil
	, ['ELSE'] = nil
	, ['ELSEIF'] = nil
	, ['END'] = nil
	, ['FOR'] = nil
	, ['IN'] = nil
	, ['UNTIL'] = nil
	, ['WHILE'] = nil
	, ['REPEAT'] = nil
	, ['BREAK'] = nil

	, ['LOCAL'] = "local "
	, ['FUNCTION'] = nil
	, ['RETURN'] = nil

-- SYMBOL
	, ['+'] = [[ + ]]
	, ['-'] = " - "
	, ['*'] = " * "
	, ['/'] = " / "
	, ['%'] = " % "
	, ['^'] = " ^ "
	, ['#'] = nil
	, ['=='] = [[ == ]]
	, ['~='] = " ~= "
	, ['<='] = " <= "
	, ['>='] = " >= "
	, ['<'] = " < "
	, ['>'] = " > "
	, ['='] = [[ = ]]
	, ['('] = "( "
	, [')'] = " )"
	, ['{'] = [[{ ]]
	, ['}'] = [[ }]]
	, ['['] = "[ "
	, [']'] = " ]"
	, [';'] = "; "
	, [':'] = nil
	, [''] = nil
	, ['.'] = nil
	, ['..'] = nil
	, ['...'] = nil
	, [','] = [[, ]]
}
