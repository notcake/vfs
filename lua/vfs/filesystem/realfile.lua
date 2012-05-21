local self = {}
VFS.RealFile = VFS.MakeConstructor (self, VFS.IFile, VFS.RealNode)

function self:ctor (path, name, parentFolder)
	self.Size = nil
end

function self:GetSize ()
	if self:GetPath ():lower ():sub (1, 5) == "data/" then
		return file.Size (self:GetPath ():sub (6))
	end
	return self.Size or -1
end

function self:Open (authId, openFlags, callback)
	openFlags = VFS.SanitizeOpenFlags (openFlags)
	callback (VFS.ReturnCode.Success, VFS.RealFileStream (self, openFlags))
end

function self:SetSize (size)
	if self:GetSize () == size then return end
	self.Size = size
	
	self:DispatchEvent ("Updated", VFS.UpdateFlags.Size)
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.Size) end
end