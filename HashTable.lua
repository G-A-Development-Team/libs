function hashTable(tbl)
    local hash = 0
    for k, v in pairs(tbl) do
        -- Convert key and value to strings, then concatenate and hash
        local keyStr = tostring(k)
        local valueStr = tostring(v)
        local entryStr = keyStr .. ":" .. valueStr
        for i = 1, #entryStr do
            hash = (hash * 31 + string.byte(entryStr, i)) % 2^32
        end
    end
    return hash
end

function areTablesEqual(tbl1, tbl2)
    return hashTable(tbl1) == hashTable(tbl2)
end
