local self = {}
VFS.MetaLuaFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (metaLuaFile, openFlags, contents)
	self.File = metaLuaFile
	self.OpenFlags = openFlags
	
	self.Contents = contents
	self.Length = self.Contents:len ()
	self.ContentsChanged = false
end

function self:CanWrite ()
	return bit.band (self.OpenFlags, VFS.OpenFlags.Write) ~= 0
end

function self:Close ()
	self:Flush ()
end

function self:Flush ()
	if not self.ContentsChanged then return end
end

function self:GetDisplayPath ()
	return self.File:GetDisplayPath ()
end

function self:GetFile ()
	return self.File
end

function self:GetLength ()
	return self.Length
end

function self:GetPath ()
	return self.File:GetPath ()
end

function self:Read (size, callback)
	callback = callback or VFS.NullCallback
	
	local startPos = self:GetPos ()
	self:Seek (startPos + size)
	
	callback (VFS.ReturnCode.Success, self.Contents:sub (startPos + 1, startPos + size))
end

function self:Write (size, data, callback)
	callback = callback or VFS.NullCallback
	callback (VFS.ReturnCode.AccessDenied)
end