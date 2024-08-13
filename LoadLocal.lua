function LoadLocal(sfile)
    sfile = sfile .. ".lua"
    file.Enumerate(function(fil)
        -- Check if 'fil' ends with the suffix specified by 'sfile'
        if string.match(fil, sfile .. "$") then
            LoadScript(fil)
        end
    end)
end
