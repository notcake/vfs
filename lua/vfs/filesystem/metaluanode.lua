local self = {}
VFS.MetaLuaNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (path, name, parentFolder)
	self.Type = "MetaLua" .. (self:IsFolder () and "Folder" or "File")
	self.Name = name
	self.ParentFolder = parentFolder
end

function self:GetName ()
	return self.Name
end

function self:GetModificationTime ()
	return -1
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return nil
end

function self:Rename (authId, name, callback)
	callback = callback or VFS.NullCallback
	callback (VFS.ReturnCode.AccessDenied)
end