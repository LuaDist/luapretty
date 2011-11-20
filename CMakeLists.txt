# Copyright (C) 2011 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( luapretty NONE )
cmake_minimum_required ( VERSION 2.6 )
include ( dist.cmake )

# Install all files and documentation
install_lua_executable ( lua-formatter src/lua-formatter.lua )
install_lua_executable ( lua-highlighter src/lua-highlighter.lua )

install ( DIRECTORY src/luapretty DESTINATION ${INSTALL_LMOD} )
install_data ( README COPYRIGHT)
install_doc ( doc/ )
