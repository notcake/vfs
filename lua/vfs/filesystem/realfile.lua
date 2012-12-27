local self = {}
VFS.RealFile = VFS.MakeConstructor (self, VFS.IFile, VFS.RealNode)

function self:ctor (path, fileSystemPath, name, parentFolder)
	self.Size = nil
end

function self:GetSize ()
	self:UpdateSize ()
	return self.Size
end

function self:Open (authId, openFlags, callback)
	openFlags = VFS.SanitizeOpenFlags (openFlags)
	callback (VFS.ReturnCode.Success, VFS.RealFileStream (self, openFlags))
end

function self:SetSize (size)
	if self.Size == size then return end
	self.Size = size
	
	self:DispatchEvent ("Updated", VFS.UpdateFlags.Size)
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.Size) end
end

function self:UpdateSize (suppressEvent)
	suppressEvent = suppressEvent or false
	
	local size = file.Size (self:GetPath (), self.FileSystemPath) or -1
	self.Size = self.Size or size -- Suppress generation of Updated event on first query
	if self.Size ~= size then
		self.Size = size
		
		if not suppressEvent then
			self:DispatchEvent ("Updated", VFS.UpdateFlags.Size)
			if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.Size) end
		end
	end
end