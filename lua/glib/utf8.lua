GLib.UTF8 = {}
GLib.UTF8.Characters = {}

function GLib.UTF8.Byte (char, offset)
	if char == "" then return -1 end
	offset = offset or 1
	
	local byte = string.byte (char, offset)
	local length = 1
	if byte >= 128 then
		if byte >= 240 then
			-- 4 byte sequence
			length = 4
			if string.len (char) < 4 then return -1, length end
			byte = (byte & 7) * 262144
			byte = byte + (string.byte (char, offset + 1) & 63) * 4096
			byte = byte + (string.byte (char, offset + 2) & 63) * 64
			byte = byte + (string.byte (char, offset + 3) & 63)
		elseif byte >= 224 then
			-- 3 byte sequence
			length = 3
			if string.len (char) < 3 then return -1, length end
			byte = (byte & 15) * 4096
			byte = byte + (string.byte (char, offset + 1) & 63) * 64
			byte = byte + (string.byte (char, offset + 2) & 63)
		elseif byte >= 192 then
			-- 2 byte sequence
			length = 2
			if string.len (char) < 2 then return -1, length end
			byte = (byte & 31) * 64
			byte = byte + (string.byte (char, offset + 1) & 63)
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
		utf8 = string.char (byte)
	elseif byte < 2048 then
		utf8 = string.format ("%c%c", 192 + math.floor (byte / 64), 128 + (byte & 63))
	elseif byte < 65536 then
		utf8 = string.format ("%c%c%c", 224 + math.floor (byte / 4096), 128 + (math.floor (byte / 64) & 63), 128 + (byte & 63))
	elseif byte < 2097152 then
		utf8 = string.format ("%c%c%c%c", 240 + math.floor (byte / 262144), 128 + (math.floor(byte / 4096) & 63), 128 + (math.floor (byte / 64) & 63), 128 + (byte & 63))
	end
	return utf8
end

function GLib.UTF8.ContainsSequences (str, offset)
	return string.find (str, "[\192-\255]", offset) and true or false
end

function GLib.UTF8.GetSequenceStart (str, offset)
	if offset <= 0 then return 1 end
	if offset > str:len () then offset = str:len () end
	
	local startOffset = offset
	while startOffset >= 1 do
		byte = string.byte (str, startOffset)
		
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
		if offset > str:len () then return nil, nil end
		
		local length = GLib.UTF8.SequenceLength (str, offset)
		local character = str:sub (offset, offset + length - 1)
		local lastOffset = offset
		offset = offset + length
		return lastOffset, character
	end
end

function GLib.UTF8.Length (str)
	local _, length = string.gsub (str, "[^\128-\191]", "")
	return length
end

function GLib.UTF8.NextChar (str, offset)
	local length = GLib.UTF8.SequenceLength (str, offset)
	return str:sub (offset, offset + length - 1), offset + length
end

function GLib.UTF8.SequenceLength (str, offset)
	local byte = string.byte (str, offset)
	if not byte then return 0
	elseif byte >= 240 then return 4
	elseif byte >= 224 then return 3
	elseif byte >= 192 then return 2
	else return 1 end
end

function GLib.UTF8.Sub (str, startCharacter, endCharacter)
	return GLib.UTF8.SubOffset (str, 1, startCharacter, endCharacter)
end

function GLib.UTF8.SubOffset (str, offset, startCharacter, endCharacter)
	if not str then return "" end
	
	if offset < 1 then offset = 1 end
	local charactersSkipped = offset - 1
	
	if startCharacter > str:len () - charactersSkipped then return "" end
	if endCharacter then
		if endCharacter < startCharacter then return "" end
		if endCharacter > str:len () - charactersSkipped then endCharacter = nil end
	end

	local iterator = GLib.UTF8.Iterator (str, offset)
	
	local nextCharacter = 1
	while nextCharacter < startCharacter do
		iterator ()
		nextCharacter = nextCharacter + 1
	end
	
	local startOffset = iterator ()
	if not startOffset then return "" end
	nextCharacter = nextCharacter + 1
	if not endCharacter then
		return str:sub (startOffset)
	end
	
	while nextCharacter <= endCharacter do
		iterator ()
		nextCharacter = nextCharacter + 1
	end
	
	local endOffset = iterator ()
	if endOffset then
		return str:sub (startOffset, endOffset - 1)
	else
		return str:sub (startOffset)
	end
end

GLib.UTF8.Characters.LeftToRightMark          = GLib.UTF8.Char (0x200E)
GLib.UTF8.Characters.RightToLeftMark          = GLib.UTF8.Char (0x200F)
GLib.UTF8.Characters.LeftToRightEmbedding     = GLib.UTF8.Char (0x202A)
GLib.UTF8.Characters.RightToLeftEmbedding     = GLib.UTF8.Char (0x202B)
GLib.UTF8.Characters.PopDirectionalFormatting = GLib.UTF8.Char (0x202C)
GLib.UTF8.Characters.LeftToRightOverride      = GLib.UTF8.Char (0x202D)
GLib.UTF8.Characters.RightToLeftOverride      = GLib.UTF8.Char (0x202E)