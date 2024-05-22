function table.Copy( tbl )
    local copy
    if type( tbl ) == "table" then
        copy = {}
        for orig_key, orig_value in next, tbl, nil do
            copy[ table.Copy( orig_key ) ] = table.Copy( orig_value )
        end
        setmetatable(copy, table.Copy( getmetatable( tbl ) ) )
    else
        copy = tbl
    end
    return copy
end

function table.ContainsValue( tbl, value )
    for _, v in pairs( tbl ) do
        if v == value then
            return true
        end
    end
    return false
end

function table.ContainsKey( tbl, key )
    for k, v in pairs( tbl ) do
        if k == key then
            return true
        end
    end
    return false
end

function table.Count( t )
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end
