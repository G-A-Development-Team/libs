function string.ToTable( input )
	local tbl = {}

	local str = tostring( input )

	for i = 1, #str do
		tbl[i] = string.sub( str, i, i )
	end

	return tbl
end

function string.Explode( separator, str, withpattern )
	if ( separator == "" ) then return string.ToTable( str ) end
	if ( withpattern == nil ) then withpattern = false end

	local ret = {}
	local current_pos = 1

	for i = 1, string.len( str ) do
		local start_pos, end_pos = string.find( str, separator, current_pos, not withpattern )
		if ( not start_pos ) then break end
		ret[ i ] = string.sub( str, current_pos, start_pos - 1 )
		current_pos = end_pos + 1
	end

	ret[ #ret + 1 ] = string.sub( str, current_pos )

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

local function RepeatText( string, amount )
    local out = ""
    for 1=1, amount do
        out = out .. string
    end
    return out
end

function string.PadLeft( str, len, pad )

    local strlen = string.len( str )
    if strlen >= len then return str end

    local padding = " "
    local paddinglen = 0

    if pad then
        if pad ~= padding then
            if string.len( pad ) > 0 then
                padding = pad
            end
        end
    end

    paddinglen = string.len( padding )

    local remainder = len-strlen

    if remainder > 0 then
        
        if remainder < paddinglen then return string.sub( padding, 1, remainder ) .. str end
        if remainder == paddinglen then return padding .. str end
        if remainder > paddinglen then

            local pamount = math.floor( remainder/paddinglen )
            local plenamount = pamount*paddinglen
            local newpadding = RepeatText( padding, pamount )
            local newpaddinglen = string.len( newpadding )
            if plenamount > remainder then 
                
                local premove = newpaddinglen-remainder
                local editpadding = string.sub( newpadding, 1, newpaddinglen-premove )
                return editpadding .. str
            elseif plenamount < remainder then

            end
        end

    end
end    


