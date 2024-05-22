function string.Explode( separator, str, withpattern )
	if ( separator == "" ) then return totable( str ) end
	if ( withpattern == nil ) then withpattern = false end

	local ret = {}
	local current_pos = 1

	for i = 1, string_len( str ) do
		local start_pos, end_pos = string_find( str, separator, current_pos, not withpattern )
		if ( not start_pos ) then break end
		ret[ i ] = string_sub( str, current_pos, start_pos - 1 )
		current_pos = end_pos + 1
	end

	ret[ #ret + 1 ] = string_sub( str, current_pos )

	return ret
end

function string.Split( str, delimiter )
	return string.Explode( delimiter, str )
end

function string.Implode( seperator, tbl ) return
	table.concat( tbl, seperator )
end

function string.Replace( str, tofind, toreplace )
	local tbl = string.Explode( tofind, str )
	if ( tbl[ 1 ] ) then return table.concat( tbl, toreplace ) end
	return str
end

function string.StartsWith( str, start )
	return string.sub( str, 1, string.len( start ) ) == start
end

function string.EndsWith( str, endStr )
	return endStr == "" or string.sub( str, -string.len( endStr ) ) == endStr
end
