GLib.UTF8 = {}
GLib.UTF8.Characters = {}

local math_floor    = math.floor
local string_byte   = string.byte
local string_char   = string.char
local string_len    = string.len
local string_find   = string.find
local string_format = string.format
local string_gsub   = string.gsub
local string_sub    = string.sub

function GLib.UTF8.Byte (char, offset)
	if char == "" then return -1 end
	offset = offset or 1
	
	local byte = string_byte (char, offset)
	local length = 1
	if byte >= 128 then
		if byte >= 240 then
			-- 4 byte sequence
			length = 4
			if string_len (char) < 4 then return -1, length end
			byte = (byte & 7) * 262144
			byte = byte + (string_byte (char, offset + 1) & 63) * 4096
			byte = byte + (string_byte (char, offset + 2) & 63) * 64
			byte = byte + (string_byte (char, offset + 3) & 63)
		elseif byte >= 224 then
			-- 3 byte sequence
			length = 3
			if string_len (char) < 3 then return -1, length end
			byte = (byte & 15) * 4096
			byte = byte + (string_byte (char, offset + 1) & 63) * 64
			byte = byte + (string_byte (char, offset + 2) & 63)
		elseif byte >= 192 then
			-- 2 byte sequence
			length = 2
			if string_len (char) < 2 then return -1, length end
			byte = (byte & 31) * 64
			byte = byte + (string_byte (char, offset + 1) & 63)
		else
			-- invalid sequence
			byte = -1
		end
	end
	return byte, length
end

function GLib.UTF8.Char (byte)
	local utf8 = ""
	if byte < 0 then
		utf8 = ""
	elseif byte <= 127 then
		utf8 = string_char (byte)
	elseif byte < 2048 then
		utf8 = string_format ("%c%c",     192 + math_floor (byte / 64),     128 + (byte & 63))
	elseif byte < 65536 then
		utf8 = string_format ("%c%c%c",   224 + math_floor (byte / 4096),   128 + (math_floor (byte / 64) & 63),   128 + (byte & 63))
	elseif byte < 2097152 then
		utf8 = string_format ("%c%c%c%c", 240 + math_floor (byte / 262144), 128 + (math_floor (byte / 4096) & 63), 128 + (math_floor (byte / 64) & 63), 128 + (byte & 63))
	end
	return utf8
end

function GLib.UTF8.ContainsSequences (str, offset)
	return string_find (str, "[\192-\255]", offset) and true or false
end

function GLib.UTF8.GetSequenceStart (str, offset)
	if offset <= 0 then return 1 end
	if offset > string_len (str) then offset = string_len (str) end
	
	local startOffset = offset
	while startOffset >= 1 do
		byte = string_byte (str, startOffset)
		
		-- Either a single byte sequence or
		-- an improperly started multi byte sequence, in which case it's treated as one byte long
		if byte <= 127 then return offset end
		
		-- Start of multibyte sequence
		if byte >= 192 then return startOffset end
		
		startOffset = startOffset - 1
	end
	return startOffset
end

function GLib.UTF8.Iterator (str, offset)
	offset = offset or 1
	if offset <= 0 then offset = 1 end
	
	return function ()
		if offset > string_len (str) then return nil, nil end
		
		local length
		
		-- Inline expansion of GLib.UTF8.SequenceLength (str, offset)
		local byte = string_byte (str, offset)
		if not byte then length = 0
		elseif byte >= 240 then length = 4
		elseif byte >= 224 then length = 3
		elseif byte >= 192 then length = 2
		else length = 1 end
		
		local character = string_sub (str, offset, offset + length - 1)
		local lastOffset = offset
		offset = offset + length
		return character, lastOffset
	end
end

function GLib.UTF8.Length (str)
	local _, length = string_gsub (str, "[^\128-\191]", "")
	return length
end

function GLib.UTF8.NextChar (str, offset)
	offset = offset or 1
	if offset <= 0 then offset = 1 end
	
	local length = GLib.UTF8.SequenceLength (str, offset)
	return string_sub (str, offset, offset + length - 1), offset + length
end

function GLib.UTF8.PreviousChar (str, offset)
	offset = offset or (string_len (str) + 1)
	if offset <= 1 then return "", 0 end
	local startOffset = GLib.UTF8.GetSequenceStart (str, offset - 1)
	local length = GLib.UTF8.SequenceLength (str, startOffset)
	return string_sub (str, startOffset, startOffset + length - 1), startOffset
end

function GLib.UTF8.SequenceLength (str, offset)
	local byte = string_byte (str, offset)
	if not byte then return 0
	elseif byte >= 240 then return 4
	elseif byte >= 224 then return 3
	elseif byte >= 192 then return 2
	else return 1 end
end

function GLib.UTF8.SplitAt (str, char)
	local c, offset = nil, 1
	local offsetChar = 1 -- character index corresponding to offset
	while c ~= "" do
		if offsetChar >= char then
			return string_sub (str, 1, offset - 1), string_sub (str, offset)
		end
		c, offset = GLib.UTF8.NextChar (str, offset)
		offsetChar = offsetChar + 1
	end
	return str
end

function GLib.UTF8.Sub (str, startCharacter, endCharacter)
	return GLib.UTF8.SubOffset (str, 1, startCharacter, endCharacter)
end

function GLib.UTF8.SubOffset (str, offset, startCharacter, endCharacter)
	if not str then return "" end
	
	if offset < 1 then offset = 1 end
	local charactersSkipped = offset - 1
	
	if startCharacter > string_len (str) - charactersSkipped then return "" end
	if endCharacter then
		if endCharacter < startCharacter then return "" end
		if endCharacter > string_len (str) - charactersSkipped then endCharacter = nil end
	end

	local iterator = GLib.UTF8.Iterator (str, offset)
	
	local nextCharacter = 1
	while nextCharacter < startCharacter do
		iterator ()
		nextCharacter = nextCharacter + 1
	end
	
	local _, startOffset = iterator ()
	if not startOffset then return "" end
	nextCharacter = nextCharacter + 1
	if not endCharacter then
		return string_sub (str, startOffset)
	end
	
	while nextCharacter <= endCharacter do
		iterator ()
		nextCharacter = nextCharacter + 1
	end
	
	local _, endOffset = iterator ()
	if endOffset then
		return string_sub (str, startOffset, endOffset - 1)
	else
		return string_sub (str, startOffset)
	end
end

GLib.UTF8.Characters.LeftToRightMark          = GLib.UTF8.Char (0x200E)
GLib.UTF8.Characters.RightToLeftMark          = GLib.UTF8.Char (0x200F)
GLib.UTF8.Characters.LeftToRightEmbedding     = GLib.UTF8.Char (0x202A)
GLib.UTF8.Characters.RightToLeftEmbedding     = GLib.UTF8.Char (0x202B)
GLib.UTF8.Characters.PopDirectionalFormatting = GLib.UTF8.Char (0x202C)
GLib.UTF8.Characters.LeftToRightOverride      = GLib.UTF8.Char (0x202D)
GLib.UTF8.Characters.RightToLeftOverride      = GLib.UTF8.Char (0x202E)