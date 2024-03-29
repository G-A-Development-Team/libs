--@Version[0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000091]

--ffi
--functions
function logger(s)
    client.color_log(48, 173, 255, s)
    print(s)
end

-- print table lib

function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    logger(output_str)
end

--json lib
-- Module options:
local always_try_using_lpeg = true
local register_global_module_table = false
local global_module_name = 'json'

--[==[

David Kolf's JSON module for Lua 5.1/5.2

Version 2.5


For the documentation see the corresponding readme.txt or visit
<http://dkolf.de/src/dkjson-lua.fsl/>.

You can contact the author by sending an e-mail to 'david' at the
domain 'dkolf.de'.


Copyright (C) 2010-2014 David Heiko Kolf

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]==]

-- global dependencies:
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
      pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat

json = { version = "dkjson 2.5" }

if register_global_module_table then
  _G[global_module_name] = json
end

local _ENV = nil -- blocking globals in Lua 5.2

pcall (function()
  -- Enable access to blocked metatables.
  -- Don't worry, this module doesn't change anything in them.
  local debmeta = require "debug".getmetatable
  if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable ({}, {
  __tojson = function () return "null" end
})

local function isarray (tbl)
  local max, n, arraylen = 0, 0, 0
  for k,v in pairs (tbl) do
    if k == 'n' and type(v) == 'number' then
      arraylen = v
      if v > max then
        max = v
      end
    else
      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
        return false
      end
      if k > max then
        max = k
      end
      n = n + 1
    end
  end
  if max > 10 and max > arraylen and max > n * 2 then
    return false -- don't create an array with too many holes
  end
  return true, max
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}

local function escapeutf8 (uchar)
  local value = escapecodes[uchar]
  if value then
    return value
  end
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

local function fsub (str, pattern, repl)
  -- gsub always builds a new string in a buffer, even when no match
  -- exists. First using find should be more efficient when most strings
  -- don't contain the pattern.
  if strfind (str, pattern) then
    return gsub (str, pattern, repl)
  else
    return str
  end
end

local function quotestring (value)
  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind (value, "[\194\216\220\225\226\239]") then
    value = fsub (value, "\194[\128-\159\173]", escapeutf8)
    value = fsub (value, "\216[\128-\132]", escapeutf8)
    value = fsub (value, "\220\143", escapeutf8)
    value = fsub (value, "\225\158[\180\181]", escapeutf8)
    value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)
    value = fsub (value, "\226\129[\160-\175]", escapeutf8)
    value = fsub (value, "\239\187\191", escapeutf8)
    value = fsub (value, "\239\191[\176-\191]", escapeutf8)
  end
  return "\"" .. value .. "\""
end
json.quotestring = quotestring

local function replace(str, o, n)
  local i, j = strfind (str, o, 1, true)
  if i then
    return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
  else
    return str
  end
end

-- locale independent num2str and str2num functions
local decpoint, numfilter

local function updatedecpoint ()
  decpoint = strmatch(tostring(0.5), "([^05+])")
  -- build a filter that can be used to remove group separators
  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str (num)
  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num (str)
  local num = tonumber(replace(str, ".", decpoint))
  if not num then
    updatedecpoint()
    num = tonumber(replace(str, ".", decpoint))
  end
  return num
end

local function addnewline2 (level, buffer, buflen)
  buffer[buflen+1] = "\n"
  buffer[buflen+2] = strrep ("  ", level)
  buflen = buflen + 2
  return buflen
end

function json.addnewline (state)
  if state.indent then
    state.bufferlen = addnewline2 (state.level or 0,
                           state.buffer, state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration

local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
  local kt = type (key)
  if kt ~= 'string' and kt ~= 'number' then
    return nil, "type '" .. kt .. "' is not supported as a key by JSON."
  end
  if prev then
    buflen = buflen + 1
    buffer[buflen] = ","
  end
  if indent then
    buflen = addnewline2 (level, buffer, buflen)
  end
  buffer[buflen+1] = quotestring (key)
  buffer[buflen+2] = ":"
  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

local function appendcustom(res, buffer, state)
  local buflen = state.bufferlen
  if type (res) == 'string' then
    buflen = buflen + 1
    buffer[buflen] = res
  end
  return buflen
end

local function exception(reason, value, state, buffer, buflen, defaultmessage)
  defaultmessage = defaultmessage or reason
  local handler = state.exception
  if not handler then
    return nil, defaultmessage
  else
    state.bufferlen = buflen
    local ret, msg = handler (reason, value, state, defaultmessage)
    if not ret then return nil, msg or defaultmessage end
    return appendcustom(ret, buffer, state)
  end
end

function json.encodeexception(reason, value, state, defaultmessage)
  return quotestring("<" .. defaultmessage .. ">")
end

encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, state)
  local valtype = type (value)
  local valmeta = getmetatable (value)
  valmeta = type (valmeta) == 'table' and valmeta -- only tables
  local valtojson = valmeta and valmeta.__tojson
  if valtojson then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    state.bufferlen = buflen
    local ret, msg = valtojson (value, state)
    if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
    tables[value] = nil
    buflen = appendcustom(ret, buffer, state)
  elseif value == nil then
    buflen = buflen + 1
    buffer[buflen] = "null"
  elseif valtype == 'number' then
    local s
    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = "null"
    else
      s = num2str (value)
    end
    buflen = buflen + 1
    buffer[buflen] = s
  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and "true" or "false"
  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring (value)
  elseif valtype == 'table' then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    level = level + 1
    local isa, n = isarray (value)
    if n == 0 and valmeta and valmeta.__jsontype == 'object' then
      isa = false
    end
    local msg
    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = "["
      for i = 1, n do
        buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder, state)
        if not buflen then return nil, msg end
        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ","
        end
      end
      buflen = buflen + 1
      buffer[buflen] = "]"
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = "{"
      local order = valmeta and valmeta.__jsonorder or globalorder
      if order then
        local used = {}
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]
          if v then
            used[k] = true
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            prev = true -- add a seperator before the next element
          end
        end
        for k,v in pairs (value) do
          if not used[k] then
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k,v in pairs (value) do
          buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
          if not buflen then return nil, msg end
          prev = true -- add a seperator before the next element
        end
      end
      if indent then
        buflen = addnewline2 (level - 1, buffer, buflen)
      end
      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    return exception ('unsupported type', value, state, buffer, buflen,
      "type '" .. valtype .. "' is not supported by JSON.")
  end
  return buflen
end

function json.encode (value, state)
  state = state or {}
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  state.buffer = buffer
  updatedecpoint()
  local ret, msg = encode2 (value, state.indent, state.level or 0,
                   buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
  if not ret then
    error (msg, 2)
  elseif oldbuffer == buffer then
    state.bufferlen = ret
    return true
  else
    state.bufferlen = nil
    state.buffer = nil
    return concat (buffer)
  end
end

local function loc (str, where)
  local line, pos, linepos = 1, 1, 0
  while true do
    pos = strfind (str, "\n", pos, true)
    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      break
    end
  end
  return "line " .. line .. ", column " .. (where - linepos)
end

local function unterminated (str, what, where)
  return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
end

local function scanwhite (str, pos)
  while true do
    pos = strfind (str, "%S", pos)
    if not pos then return nil end
    local sub2 = strsub (str, pos, pos + 1)
    if sub2 == "\239\187" and strsub (str, pos + 2, pos + 2) == "\191" then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    elseif sub2 == "//" then
      pos = strfind (str, "[\n\r]", pos + 2)
      if not pos then return nil end
    elseif sub2 == "/*" then
      pos = strfind (str, "*/", pos + 2)
      if not pos then return nil end
      pos = pos + 2
    else
      return pos
    end
  end
end

local escapechars = {
  ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
  ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
}

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring (str, pos)
  local lastpos = pos + 1
  local buffer, n = {}, 0
  while true do
    local nextpos = strfind (str, "[\"\\]", lastpos)
    if not nextpos then
      return unterminated (str, "string", pos)
    end
    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub (str, lastpos, nextpos - 1)
    end
    if strsub (str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub (str, nextpos + 1, nextpos + 1)
      local value
      if escchar == "u" then
        value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)
        if value then
          local value2
          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub (str, nextpos + 6, nextpos + 7) == "\\u" then
              value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)
              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end
          value = value and unichar (value)
          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end
      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end
      n = n + 1
      buffer[n] = value
    end
  end
  if n == 1 then
    return buffer[1], lastpos
  elseif n > 1 then
    return concat (buffer), lastpos
  else
    return "", lastpos
  end
end

local scanvalue -- forward declaration

local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  local len = strlen (str)
  local tbl, n = {}, 0
  local pos = startpos + 1
  if what == 'object' then
    setmetatable (tbl, objectmeta)
  else
    setmetatable (tbl, arraymeta)
  end
  while true do
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    local char = strsub (str, pos, pos)
    if char == closechar then
      return tbl, pos + 1
    end
    local val1, err
    val1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
    if err then return nil, pos, err end
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    char = strsub (str, pos, pos)
    if char == ":" then
      if val1 == nil then
        return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
      end
      pos = scanwhite (str, pos + 1)
      if not pos then return unterminated (str, what, startpos) end
      local val2
      val2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
      if err then return nil, pos, err end
      tbl[val1] = val2
      pos = scanwhite (str, pos)
      if not pos then return unterminated (str, what, startpos) end
      char = strsub (str, pos, pos)
    else
      n = n + 1
      tbl[n] = val1
    end
    if char == "," then
      pos = pos + 1
    end
  end
end

scanvalue = function (str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  pos = scanwhite (str, pos)
  if not pos then
    return nil, strlen (str) + 1, "no valid JSON value (reached the end)"
  end
  local char = strsub (str, pos, pos)
  if char == "{" then
    return scantable ('object', "}", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "[" then
    return scantable ('array', "]", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "\"" then
    return scanstring (str, pos)
  else
    local pstart, pend = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
    if pstart then
      local number = str2num (strsub (str, pstart, pend))
      if number then
        return number, pend + 1
      end
    end
    pstart, pend = strfind (str, "^%a%w*", pos)
    if pstart then
      local name = strsub (str, pstart, pend)
      if name == "true" then
        return true, pend + 1
      elseif name == "false" then
        return false, pend + 1
      elseif name == "null" then
        return nullval, pend + 1
      end
    end
    return nil, pos, "no valid JSON value at " .. loc (str, pos)
  end
end

local function optionalmetatables(...)
  if select("#", ...) > 0 then
    return ...
  else
    return {__jsontype = 'object'}, {__jsontype = 'array'}
  end
end

function json.decode (str, pos, nullval, ...)
  local objectmeta, arraymeta = optionalmetatables(...)
  return scanvalue (str, pos, nullval, objectmeta, arraymeta)
end

function json.use_lpeg ()
  local g = require ("lpeg")

  if g.version() == "0.11" then
    error "due to a bug in LPeg 0.11, it cannot be used for JSON matching"
  end

  local pegmatch = g.match
  local P, S, R = g.P, g.S, g.R

  local function ErrorCall (str, pos, msg, state)
    if not state.msg then
      state.msg = msg .. " at " .. loc (str, pos)
      state.pos = pos
    end
    return false
  end

  local function Err (msg)
    return g.Cmt (g.Cc (msg) * g.Carg (2), ErrorCall)
  end

  local SingleLineComment = P"//" * (1 - S"\n\r")^0
  local MultiLineComment = P"/*" * (1 - P"*/")^0 * P"*/"
  local Space = (S" \n\r\t" + P"\239\187\191" + SingleLineComment + MultiLineComment)^0

  local PlainChar = 1 - S"\"\\\n\r"
  local EscapeSequence = (P"\\" * g.C (S"\"\\/bfnrt" + Err "unsupported escape sequence")) / escapechars
  local HexDigit = R("09", "af", "AF")
  local function UTF16Surrogate (match, pos, high, low)
    high, low = tonumber (high, 16), tonumber (low, 16)
    if 0xD800 <= high and high <= 0xDBff and 0xDC00 <= low and low <= 0xDFFF then
      return true, unichar ((high - 0xD800)  * 0x400 + (low - 0xDC00) + 0x10000)
    else
      return false
    end
  end
  local function UTF16BMP (hex)
    return unichar (tonumber (hex, 16))
  end
  local U16Sequence = (P"\\u" * g.C (HexDigit * HexDigit * HexDigit * HexDigit))
  local UnicodeEscape = g.Cmt (U16Sequence * U16Sequence, UTF16Surrogate) + U16Sequence/UTF16BMP
  local Char = UnicodeEscape + EscapeSequence + PlainChar
  local String = P"\"" * g.Cs (Char ^ 0) * (P"\"" + Err "unterminated string")
  local Integer = P"-"^(-1) * (P"0" + (R"19" * R"09"^0))
  local Fractal = P"." * R"09"^0
  local Exponent = (S"eE") * (S"+-")^(-1) * R"09"^1
  local Number = (Integer * Fractal^(-1) * Exponent^(-1))/str2num
  local Constant = P"true" * g.Cc (true) + P"false" * g.Cc (false) + P"null" * g.Carg (1)
  local SimpleValue = Number + String + Constant
  local ArrayContent, ObjectContent

  -- The functions parsearray and parseobject parse only a single value/pair
  -- at a time and store them directly to avoid hitting the LPeg limits.
  local function parsearray (str, pos, nullval, state)
    local obj, cont
    local npos
    local t, nt = {}, 0
    repeat
      obj, cont, npos = pegmatch (ArrayContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      nt = nt + 1
      t[nt] = obj
    until cont == 'last'
    return pos, setmetatable (t, state.arraymeta)
  end

  local function parseobject (str, pos, nullval, state)
    local obj, key, cont
    local npos
    local t = {}
    repeat
      key, obj, cont, npos = pegmatch (ObjectContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      t[key] = obj
    until cont == 'last'
    return pos, setmetatable (t, state.objectmeta)
  end

  local Array = P"[" * g.Cmt (g.Carg(1) * g.Carg(2), parsearray) * Space * (P"]" + Err "']' expected")
  local Object = P"{" * g.Cmt (g.Carg(1) * g.Carg(2), parseobject) * Space * (P"}" + Err "'}' expected")
  local Value = Space * (Array + Object + SimpleValue)
  local ExpectedValue = Value + Space * Err "value expected"
  ArrayContent = Value * Space * (P"," * g.Cc'cont' + g.Cc'last') * g.Cp()
  local Pair = g.Cg (Space * String * Space * (P":" + Err "colon expected") * ExpectedValue)
  ObjectContent = Pair * Space * (P"," * g.Cc'cont' + g.Cc'last') * g.Cp()
  local DecodeValue = ExpectedValue * g.Cp ()

  function json.decode (str, pos, nullval, ...)
    local state = {}
    state.objectmeta, state.arraymeta = optionalmetatables(...)
    local obj, retpos = pegmatch (DecodeValue, str, pos, nullval, state)
    if state.msg then
      return nil, state.pos, state.msg
    else
      return obj, retpos
    end
  end

  -- use this function only once:
  json.use_lpeg = function () return json end

  json.using_lpeg = true

  return json -- so you can get the module using json = require "dkjson".use_lpeg()
end

    
    
-- gui custom stuff
function gui._Custom(ref, varname, name, x, y, w, h, paint, custom_vars)
	local tbl = {val = 0}

	local function read(v)
		tbl.val = v
	end

	local function write()
		return tbl.val
	end
	
	local function is_in_rect(x, y, x1, y1, x2, y2)
		return x >= x1 and x < x2 and y >= y1 and y < y2;
	end
	
	local GuiObject = {
		element = nil,
		custom_vars = custom_vars or {},
		name = name,
		
		_element_pos_x = x,
		_element_pos_y = y,
		
		_element_width = w,
		_element_height = h,
		
		
		
		_parent = ref,
			
		GetValue = function(self)
			return self.element:GetValue()
		end,
		
		SetValue = function(self, value)
			return self.element:SetValue(value)
		end,
		
		GetName = function(self)
			return self.name
		end,
		
		SetName = function(self, name)
			self.name = name
		end,
		
		SetPosX = function(self, x)
			self.element:SetPosX(x)
			self._element_pos_x = x
		end,
		
		SetPosY = function(self, y)
			self.element:SetPosY(y)
			self._element_pos_y = y
		end,
		
		SetPos = function(self, x, y)
			self.element:SetPosX(x)
			self.element:SetPosY(y)
			self._element_pos_x = x
			self._element_pos_y = y
		end,
		
		GetPos = function(self)
			return self._element_pos_x, self._element_pos_y
		end,
		
		SetWidth = function(self, width)
			self.element:SetWidth(width)
			self._element_width = width
		end,
		
		SetHeight = function(self, height)
			self.element:SetHeight(height)
			self._element_height = height
		end,
		
		SetSize = function(self, w, h)
			self.element:SetWidth(w)
			self.element:SetHeight(h)
			self._element_width = width
			self._element_height = height
		end,
		
		GetSize = function(self)
			return self._element_width, self._element_height 
		end,
		
		SetVisible = function(self, b)
			self.element:SetInvisible(not b)
		end,
		
		SetInvisible = function(self, b)
			self.element:SetInvisible(b)
		end,
		
		GetParent = function(self)
			return self._parent
		end,
		
		_mouse_left_released = true,
		_old_mouse_left_released = true,
		
		OnClick = function(self) -- you rewrite this function when creating elements
			
		end,
				
		hovering = function(x, y, x2, y2)
			local mx, my = input.GetMousePos()
			return is_in_rect(mx, my, x, y, x2, y2)
		end,
		
		_mouse_hovering = false,
		_old_mouse_hovering = false,
		OnHovered = function(self)
			
		end,	
	}
	
	local meta = {__index = custom_vars}
	setmetatable(GuiObject, meta)
	
	local function _paint(x, y, x2, y2, active)
	
		local mx, my = input.GetMousePos()
		local hovering = GuiObject.hovering(x, y, x2, y2)
		
		if hovering then
			GuiObject._mouse_hovering = true		
			if input.IsButtonReleased(1) then
				GuiObject._mouse_left_released = true
			end
		
			if input.IsButtonDown(1) then
				GuiObject._mouse_left_released = false
			end
		
			if GuiObject._mouse_left_released ~= GuiObject._old_mouse_left_released then
				if not GuiObject._mouse_left_released then -- Clicked
					GuiObject:OnClick()
				end
				GuiObject._old_mouse_left_released = GuiObject._mouse_left_released
			end
		else
			GuiObject._mouse_hovering = false
		end

		if GuiObject._old_mouse_hovering ~= GuiObject._mouse_hovering then
			-- print(GuiObject._mouse_hovering)
			GuiObject:OnHovered(GuiObject._mouse_hovering)
			GuiObject._old_mouse_hovering = GuiObject._mouse_hovering
		end
		
		local width = x2 - x
		local height = y2 - y
		paint(x, y, x2, y2, active, GuiObject, width, height)
	end
	
	local custom = gui.Custom(ref, varname, x, y, w, h, _paint, write, read)
	GuiObject.element = custom
	
	return GuiObject
end


function gui.ColoredText(ref, text, x, y, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		local options = self.custom_vars
	
		-- text
		draw.Color(options.text_color[1], options.text_color[2], options.text_color[3])		
		draw.SetFont(options.font)
		draw.Text(x, y, options.text)		
		
		--underline
		if options.underline then
			local text_x, text_y = draw.GetTextSize(options.text)
			local underline_space = 5
			draw.Color(options.underline_color[1], options.underline_color[2], options.underline_color[3], options.underline_color[4])
			draw.Line(x, y + text_y + underline_space, x + text_x, y + text_y + underline_space)
		end
		
	
	end
	local options = options or {}
	
	local vars = {
		text = text,
		text_color = options.text_color and {options.text_color[1] or 255, options.text_color[2] or 255, options.text_color[3] or 255, options.text_color[4] or 255} or {255,255,255,255},
		font = options.font or draw.CreateFont("Bahnschrift", 14),
		
		underline = options.underline or false,
	}
	vars.underline_color = options.underline_color and {options.underline_color[1] or 255, options.underline_color[2] or 255, options.underline_color[3] or 255, options.underline_color[4] or 255} or vars.text_color

	

	local text_x, text_y = draw.GetTextSize(text)
	local custom = gui._Custom(ref, "", "", x, y, text_x, text_y, paint, vars)
		
	function custom:SetOptions(options)
		vars.text = options.text or vars.text
		vars.font = options.font or vars.font
		vars.text_color = options.text_color and {options.text_color[1] or 255, options.text_color[2] or 255, options.text_color[3] or 255, options.text_color[4] or 255} or vars.text_color
		vars.underline = options.underline
		vars.underline_color = options.underline_color and {options.underline_color[1] or 255, options.underline_color[2] or 255, options.underline_color[3] or 255, options.underline_color[4] or 255} or vars.underline_color
		
		local text_x, text_y = draw.GetTextSize(vars.text)
		self:SetSize(text_x, text_y)
	end
		
	return custom
end

function gui.LinkText(ref, text, x, y, options)

	local linked_text = gui.ColoredText(ref, text, x, y, {text_color = {0, 70, 255}})	
	linked_text.OnHovered = function(self, IsHovering)
		self:SetOptions({underline = IsHovering})
	end
	
	linked_text.DoClick = function(self)
		print("Clicked")
	end

	return linked_text
end


-- Examples


-- local test_tab = gui.Tab(gui.Reference("Misc"), "test.tab", "Test tab")

-- local font = draw.CreateFont("Bahnschrift", 14)
-- local text = gui.ColoredText(test_tab, "Hello world", 100, 100, {
	-- font = font,
	-- text_color = {255,0,0}
-- })

-- text.OnClick = function(self)
	-- self:SetOptions({text = "I have been clicked!"})
-- end

-- local linked_texted = gui.LinkText(test_tab, "Hello world", 200, 200)
	
--Thanks to qi 
local math_sin = math.sin
local math_cos = math.cos
local math_rad = math.rad
local math_abs = math.abs
local math_modf = math.modf
local math_floor = math.floor
local math_pi = 3.1415926535898

local tostring = tostring
local string_len = string.len
local string_sub = string.sub
local string_gsub = string.gsub
local string_match = string.match
local string_format = string.format

local ipairs = ipairs
local table_insert = table.insert
local setmetatable = setmetatable
local tonumber = tonumber
local type = type

local draw_Line,
    draw_OutlinedRect,
    draw_RoundedRectFill,
    draw_ShadowRect,
    draw_GetScreenSize,
    draw_SetFont,
    draw_GetTextSize,
    draw_FilledCircle,
    draw_OutlinedCircle,
    draw_SetScissorRect,
    draw_FilledRect,
    draw_SetTexture =
    draw.Line,
    draw.OutlinedRect,
    draw.RoundedRectFill,
    draw.ShadowRect,
    draw.GetScreenSize,
    draw.SetFont,
    draw.GetTextSize,
    draw.FilledCircle,
    draw.OutlinedCircle,
    draw.SetScissorRect,
    draw.FilledRect,
    draw.SetTexture
local draw_UpdateTexture,
    draw_TextShadow,
    draw_CreateTexture,
    draw_Triangle,
    draw_AddFontResource,
    draw_Color,
    draw_RoundedRect,
    draw_CreateFont,
    draw_Text =
    draw.UpdateTexture,
    draw.TextShadow,
    draw.CreateTexture,
    draw.Triangle,
    draw.AddFontResource,
    draw.Color,
    draw.RoundedRect,
    draw.CreateFont,
    draw.Text
local common_DecodePNG, common_DecodeJPEG, common_RasterizeSVG = common.DecodePNG, common.DecodeJPEG, common.RasterizeSVG

renderer = renderer or {screen_size = draw_GetScreenSize}

local function math_round(number, precision)
    local mult = 10 ^ (precision or 0)
    return math_floor(number * mult + 0.5) / mult
end

local function assert(expression, message, level, ...)
    if (not expression) then
        error(string_format(message, ...), 4)
    end
end

local function bad_argument(expression, name, expected)
    assert(type(expression) == expected, " bad argument #1 to '%s' (%s expected, got %s)", 4, name, expected, tostring(type(expression)))
end

local dpi, dpi_scale = 0, {0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3}
local function renderer_font(flags)
    if flags:find("d") and dpi ~= dpi_scale[gui.GetValue("adv.dpi") + 1] or not font then
        dpi = dpi_scale[gui.GetValue("adv.dpi") + 1]
        font = {
            def = draw_CreateFont("Verdana", 15),
            default = {draw_CreateFont("Verdana", 15 * dpi), draw_CreateFont("Verdana", 15 * dpi, 600)},
            large = {draw_CreateFont("Verdana", 18 * dpi), draw_CreateFont("Verdana", 18 * dpi, 600)},
            centered = {draw_CreateFont("Verdana", 12 * dpi), draw_CreateFont("Verdana", 12 * dpi, 600)},
            segoe_ui = draw_CreateFont("segoe ui", 30, 600)
        }
    end

    draw_SetFont(font.default[1])
    if flags:find("b") then
        draw_SetFont(font.default[2])
    end

    if flags:find("+") then
        draw_SetFont(font.large[1])

        if flags:find("b") then
            draw_SetFont(font.large[2])
        end
    end

    if flags:find("-") then
        draw_SetFont(font.centered[1])

        if flags:find("b") then
            draw_SetFont(font.centered[2])
        end
    end
end

function renderer.color(...)
    local arg = {...}
    local color_list = {}

    if type(arg[1]) == "number" then
        for i, v in ipairs(arg) do
            table_insert(color_list, v)
        end
    elseif type(arg[1]) == "string" then
        local hex = string_gsub(..., "#", "")
        local index = 1
        while index < string_len(hex) do
            local hex_sub = string_sub(hex, index, index + 1)
            table_insert(color_list, tonumber(hex_sub, 16) or error("parameter of error", 2))
            index = index + 2
        end
    end

    local r = color_list[1] or 255
    local g = color_list[2] or 255
    local b = color_list[3] or 255
    local a = color_list[4] or 255

    draw_Color(r, g, b, a)
    return r, g, b, a
end

function renderer.measure_text(flags, ...)
    local arg = {...}
    local string = ""

    bad_argument(flags, "measure_text", "string")

    for i, v in ipairs(arg) do
        string = string .. tostring(v)
    end

    renderer_font(flags)

    local width, height = draw_GetTextSize(string)

    return width, height
end

function renderer.text(x, y, r, g, b, a, flags, ...)
    local arg = {...}
    bad_argument(x and y, "text", "number")
    bad_argument(flags, "text", "string")

    local x = math_round(x)
    local y = math_round(y)

    local string = ""

    for i, v in ipairs(arg) do
        string = string .. tostring(v)
    end

    renderer_font(flags)

    local w = renderer.measure_text(flags, ...)

    if flags:find("c") then
        x = x - math_round(w * 0.5)
    end
    if flags:find("r") then
        x = x - w
    end
    if flags:find("s") then
        renderer.color(0, 0, 0, a)
        draw_Text(x + 1, y + 1, string)
    end

    renderer.color(r, g, b, a)
    draw_Text(x, y, string)

    draw_SetFont(font.def)
    renderer.color()
end

function renderer.rectangle(x, y, w, h, r, g, b, a, flags, radius)
    bad_argument(x and y and w and h, "rectangle", "number")
    bad_argument(flags, "rectangle", "string")

    renderer.color(r, g, b, a)

    local w = (w < 0) and (x - math_abs(w)) or x + w
    local h = (h < 0) and (y - math_abs(h)) or y + h

    if flags:find("f") then
        draw_FilledRect(x, y, w, h)
    elseif flags:find("o") then
        draw_OutlinedRect(x, y, w, h)
    elseif flags:find("s") then
        draw_ShadowRect(x, y, w, h, radius or 0)
    end

    renderer.color()
end

function renderer.line(xa, ya, xb, yb, r, g, b, a)
    bad_argument(xa and ya and xb and yb, "line", "number")
    renderer.color(r, g, b, a)
    draw_Line(xa, ya, xb, yb)
    renderer.color()
end

function renderer.gradient(x, y, w, h, r1, g1, b1, a1, r2, g2, b2, a2, ltr)
    bad_argument(x and y and w and h, "gradient", "number")

    local abs_w = math_abs(w)
    local abs_h = math_abs(h)

    local rectangle = renderer.rectangle
    if ltr then
        if a1 ~= 0 then
            if a1 and a2 ~= 255 then
                for i = 1, abs_w do
                    local a1 = i / abs_w * a1
                    local x = (w < 0) and (x + w + i - 1) or (x + i - 1)
                    rectangle(x, y, 1, h, r1, g1, b1, a1, "f")
                end
            else
                rectangle(x, y, w, h, r1, g1, b1, a1, "f")
            end
        end

        if a2 ~= 0 then
            for i = 1, abs_w do
                local a2 = i / abs_w * a2
                local x = (w < 0) and (x - i) or (x + w - i)
                rectangle(x, y, 1, h, r2, g2, b2, a2, "f")
            end
        end
    else
        if a1 ~= 0 then
            if a1 and a2 ~= 255 then
                for i = 1, abs_h do
                    local a1 = i / abs_h * a1
                    local y = (h < 0) and (y + h + i - 1) or (y + i - 1)
                    rectangle(x, y, w, 1, r1, g1, b1, a1, "f")
                end
            else
                rectangle(x, y, w, h, r1, g1, b1, a1, "f")
            end
        end
        if a2 ~= 0 then
            for i = 1, abs_h do
                local a2 = i / abs_h * a2
                local y = (h < 0) and (y - i) or (y + h - i)
                rectangle(x, y, w, 1, r2, g2, b2, a2, "f")
            end
        end
    end
end

function renderer.circle(x, y, r, g, b, a, radius, flags)
    bad_argument(x and y and radius, "circle ", "number")
    bad_argument(flags, "circle", "string")

    renderer.color(r, g, b, a)

    if flags:find("f") then
        draw_FilledCircle(x, y, radius)
    elseif flags:find("o") then
        draw_OutlinedCircle(x, y, radius)
    end

    renderer.color()
end

function renderer.circle_outline(x, y, r, g, b, a, radius, start_degrees, percentage, thickness, radian)
    bad_argument(x and y and radius and start_degrees and percentage and thickness, "circle_outline", "number")

    local thickness = radius - thickness
    local percentage = math_abs(percentage * 360)
    local radian = radian or 1

    renderer.color(r, g, b, a)

    for i = start_degrees + radian, start_degrees + percentage, radian do
        local cos_1 = math_cos(i * math_pi / 180)
        local sin_1 = math_sin(i * math_pi / 180)
        local cos_2 = math_cos((i + radian) * math_pi / 180)
        local sin_2 = math_sin((i + radian) * math_pi / 180)

        local x0 = x + cos_2 * thickness
        local y0 = y + sin_2 * thickness
        local x1 = x + cos_1 * radius
        local y1 = y + sin_1 * radius
        local x2 = x + cos_2 * radius
        local y2 = y + sin_2 * radius
        local x3 = x + cos_1 * thickness
        local y3 = y + sin_1 * thickness

        draw_Triangle(x1, y1, x2, y2, x3, y3)
        draw_Triangle(x3, y3, x2, y2, x0, y + sin_2 * thickness)
    end
    renderer.color()
end

function renderer.triangle(x0, y0, x1, y1, x2, y2, r, g, b, a)
    bad_argument(x0 and y0 and x1 and y1 and x2 and y2, "triangle", "number")

    renderer.color(r, g, b, a)
    draw_Triangle(x0, y0, x1, y1, x2, y2)
    renderer.color()
end

function renderer.rectangle_rounded(x, y, w, h, r, g, b, a, radius, flags, tl, tr, bl, br)
    bad_argument(x and y and w and h and radius, "rectangle_rounded", "number")

    local tl = tl or 0
    local tr = tr or 0
    local bl = bl or 0
    local br = br or 0

    local w = (w < 0) and (x - math_abs(w)) or x + w
    local h = (h < 0) and (y - math_abs(h)) or y + h

    renderer.color(r, g, b, a)

    if flags:find("f") then
        draw_RoundedRectFill(x, y, w, h, radius, tl, tr, bl, br)
    elseif flags:find("o") then
        draw_RoundedRect(x, y, w, h, radius, tl, tr, bl, br)
    end

    renderer.color()
end

local indicator_object = {}

function renderer.new_indicator()
    local lp = entities.GetLocalPlayer()

    if not (lp and lp:IsAlive()) then
        return
    end

    local temp = {}

    local screen_size = {draw_GetScreenSize()}
    local y = screen_size[2] / 1.4105 - #temp * 35

    for i = 1, #indicator_object do
        table_insert(temp, indicator_object[i])
    end

    if (not font) then
        renderer_font()
    end

    draw_SetFont(font.segoe_ui)
    local gradient = renderer.gradient

    for i = 1, #temp do
        local __ind = temp[i]

        local w, h = draw_GetTextSize(__ind.string)

        gradient(12 + (w * 0.5), y - (h * 0.25), (w * 0.5), h * 2, 0, 0, 0, 0, 0, 0, 0, 50, true)
        gradient(12, y - (h * 0.25), (w * 0.5) + 0.5, h * 2, 0, 0, 0, 50, 0, 0, 0, 0, true)

        renderer.color(__ind.r, __ind.g, __ind.b, __ind.a)
        draw_Text(15, y, __ind.string)

        y = y - 35
    end

    indicator_object = {}

    renderer.color()
end

function renderer.indicator(r, g, b, a, ...)
    local arg = {...}
    local string = ""

    bad_argument(arg[1], "indicator", "string")

    for i, v in ipairs(arg) do
        string = string .. tostring(v)
    end

    local indicator = {}

    local i = #indicator_object + 1
    indicator_object[i] = {}

    setmetatable(indicator_object[i], indicator)

    indicator.__index = indicator
    indicator.r = r or 255
    indicator.g = g or 255
    indicator.b = b or 255
    indicator.a = a or 255
    indicator.string = string or ""

    return indicator_object[i]
end

function renderer.load_svg(contents, scale)
    local rgba, width, height = common_RasterizeSVG(contents or nil, scale or 1)
    local texture = draw_CreateTexture(rgba, width, height)
    return texture, {rgba, width, height}
end

function renderer.load_png(contents)
    local rgba, width, height = common_DecodePNG(contents)
    local texture = draw_CreateTexture(rgba, width, height)
    return texture, {rgba, width, height}
end

function renderer.load_jpg(contents)
    local rgba, width, height = common.DecodeJPEG(contents or nil)
    local texture = draw_CreateTexture(rgba, width, height)
    return texture, {rgba, width, height}
end

function renderer.texture(texture, x, y, w, h, r, g, b, a)
    bad_argument(x and y and w and h, "texture", "number")

    draw_SetTexture(texture)
    renderer.rectangle(x, y, w, h, r, g, b, a, "f")
    draw_SetTexture(nil)
end

return renderer

