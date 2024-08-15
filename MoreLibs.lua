function getSecondToLastItem(tbl)
    local keys = {}
    
    -- Collect all the keys from the table
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
    
    -- Sort the keys
    table.sort(keys)
    
    -- Check if there are at least two elements
    if #keys < 2 then
        return nil, "Not enough elements in the table"
    end
    
    -- Get the second to last key
    local secondToLastKey = keys[#keys - 1]
    
    -- Return the value associated with this key
    return tbl[secondToLastKey]
end

-- Function to wrap text into lines that fit within width W
function wrapText(words, maxWidth)
    local lines = {}
    local currentLine = ""

    for _, word in ipairs(words) do
        local testLine = currentLine .. (currentLine == "" and "" or " ") .. word
        local testWidth, _ = draw.GetTextSize(testLine)

        if testWidth > maxWidth then
            table.insert(lines, currentLine)
            currentLine = word
        else
            currentLine = testLine
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end
