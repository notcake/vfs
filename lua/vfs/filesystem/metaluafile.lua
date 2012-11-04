local self = {}
VFS.MetaLuaFile = VFS.MakeConstructor (self, VFS.IFile, VFS.MetaLuaNode)

function self:ctor (path, name, parentFolder)
	self.Size = nil
end

function self:GetSize ()
	return self.Size or -1
end

function self:Open (authId, openFlags, callback)
	callback = callback or VFS.NullCallback
	openFlags = VFS.SanitizeOpenFlags (openFlags)
	
	if not potcfileapi then
		callback (VFS.ReturnCode.AccessDenied)
		return
	end
	
	potcfileapi.readFile (self:GetPath (),
		function (returnCode, contents)
			contents = contents or ""
			
			if not returnCode then
				callback (VFS.ReturnCode.AccessDenied)
				return
			end
			
			self:SetSize (contents:len ())
			callback (VFS.ReturnCode.Success, VFS.MetaLuaFileStream (self, openFlags, contents))
		end
	)
end

function self:SetSize (size)
	if self:GetSize () == size then return end
	self.Size = size
	
	self:DispatchEvent ("Updated", VFS.UpdateFlags.Size)
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.Size) end
end