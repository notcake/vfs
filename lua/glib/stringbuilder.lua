local self = {}
GLib.StringBuilder = GLib.MakeConstructor (self)

local string_len = string.len

function self:ctor ()
	self.Buffer = { "" }
	self.Length = 0
end

function self:Append (str)
	str = tostring (str)
	if string_len (self.Buffer [#self.Buffer]) >= 1024 then
		self.Buffer [#self.Buffer + 1] = ""
	end
	self.Buffer [#self.Buffer] = self.Buffer [#self.Buffer] .. str
	self.Length = self.Length + string_len  (str)
	
	return self
end

function self:Clear ()
	self.Buffer = { "" }
	self.Length = 0
end

function self:GetLength ()
	return self.Length
end

function self:ToString ()
	return table.concat (self.Buffer)
end

self.__concat = self.Append
self.__len    = self.GetLength