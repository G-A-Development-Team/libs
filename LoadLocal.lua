function LoadLocal(sfile)
    sfile = sfile .. ".lua"
    local suffix_length = #sfile

    file.Enumerate(function(fil)
        -- Check if 'fil' ends with the suffix specified by 'sfile'
        if #fil >= suffix_length and string.sub(fil, -suffix_length) == sfile then
            LoadScript( fil )
        end
    end)
end
