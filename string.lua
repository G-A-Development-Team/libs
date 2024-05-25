function string.ToTable( input )
	local tbl = {}

	local str = tostring( input )

	for i = 1, #str do
		tbl[i] = string.sub( str, i, i )
	end

	return tbl
end

function string.Explode( separator, str )
	if ( separator == "" ) then return string.ToTable( str ) end
	local ret = {}
	local current_pos = 1

	for i = 1, string.len( str ) do
		local start_pos, end_pos = string.find( str, separator, current_pos, true )
		if ( not start_pos ) then break end
		ret[ i ] = string.sub( str, current_pos, start_pos - 1 )
		current_pos = end_pos + 1
	end

	ret[ #ret + 1 ] = string.sub( str, current_pos )
    return ret
end
