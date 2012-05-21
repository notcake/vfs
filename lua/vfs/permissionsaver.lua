local self = {}
VFS.PermissionSaver = VFS.MakeConstructor (self)

function self:ctor ()
	self.Version = 1

	self.NeedsSaving = false
	self.IgnorePermissionsChanged = false
	
	self.HookedNodes = VFS.WeakKeyTable ()
	self.SavableNodes = VFS.WeakKeyTable ()
	self.SavedBlocks = {}
	
	timer.Create ("VFS.PermissionSaver", 10, 0,
		function ()
			if not self.NeedsSaving then return end
			self:Save ()
		end
	)
	
	self.NodeCreated = function (node, childNode)
		if childNode:IsFolder () then
			self:HookNode (childNode)
			-- PermissionSaver:HookNode () will automatically load up permissions on the node
			-- it's given
		else
			if childNode:IsLocalNode () then
				self.SavableNodes [childNode] = true
			end
			if childNode:IsLocalNode () and self.SavedBlocks [childNode:GetPath ()] then
				self.IgnorePermissionsChanged = true
				childNode:GetPermissionBlock ():Deserialize (self.SavedBlocks [childNode:GetPath ()])
				self.IgnorePermissionsChanged = false
			end
		end
	end
	
	self.NodeDeleted = function (node, childNode)
		if self:IsNodeHooked (childNode) then self:UnhookNode (childNode) end
		self.SavableNodes [childNode] = nil
	end
	
	self.NodePermissionsChanged = function (node, childNode)
		if self.IgnorePermissionsChanged then return end
		if self.SavableNodes [childNode] then
			ErrorNoHalt (childNode:GetPath () .. "\n")
			self:FlagUnsaved ()
		end
	end
	
	self.NodeRenamed = function (node, childNode, oldName, newName)
		if not self.SavableNodes [childNode] then return end
	
		local path = childNode:GetPath ()
		local parts = path:Split ("/")
		path [#path] = oldName
		local oldPath = table.concat (path, "/")
		self.SavedBlocks [childNode:GetPath ()] = self.SavedBlocks [oldPath]
		self.SavedBlocks [oldPath] = nil
	end
end

function self:dtor ()
	timer.Destroy ("VFS.PermissionSaver")

	if not self.NeedsSaving then return end
	self:Save ()
end

function self:HookNode (node)
	self.HookedNodes [node] = true
	if not node:IsRoot () and node:IsLocalNode () then
		self.SavableNodes [node] = true
	end
	
	if node:IsLocalNode () and self.SavedBlocks [node:GetPath ()] then
		self.IgnorePermissionsChanged = true
		node:GetPermissionBlock ():Deserialize (self.SavedBlocks [node:GetPath ()])
		self.IgnorePermissionsChanged = false
	end
	
	node:AddEventListener ("NodeCreated",            tostring (self), self.NodeCreated)
	node:AddEventListener ("NodeDeleted",            tostring (self), self.NodeDeleted)
	node:AddEventListener ("NodePermissionsChanged", tostring (self), self.NodePermissionsChanged)
	node:AddEventListener ("NodeRenamed",            tostring (self), self.NodeRenamed)
end

function self:HookNodeRecursive (node)
	self:HookNode (node)
	
	if node:IsFolder () then
		for _, childNode in pairs (node:EnumerateChildrenSynchronous ()) do
			if childNode:IsFolder () then
				self:HookNodeRecursive (childNode)
			end
		end
	end
end

function self:IsNodeHooked (node)
	return self.HookedNodes [node] or false
end

function self:UnhookNode (node)
	self.HookedNodes [node] = nil
	self.SavableNodes [node] = nil
	
	node:RemoveEventListener ("NodeCreated",            tostring (self))
	node:RemoveEventListener ("NodeDeleted",            tostring (self))
	node:RemoveEventListener ("NodePermissionsChanged", tostring (self))
	node:RemoveEventListener ("NodeRenamed",            tostring (self))
end

function self:FlagUnsaved ()
	self.NeedsSaving = true
end

function self:Load (callback)
	callback = callback or VFS.NullCallback

	local data = file.Read ("vfs_" .. (SERVER and "sv" or "cl") .. ".txt") or ""
	if data == "" then callback (VFS.ReturnCode.Success) return end
	local inBuffer = VFS.StringInBuffer (data)
	inBuffer:String () -- discard warning
	local version = inBuffer:UInt32 ()
	if version ~= self.Version then
		VFS.Error ("VFS.PermissionSaver:Load : Cannot load version " .. version .. " files. Current version is " .. self.Version .. ".")
		callback (VFS.ReturnCode.Success)
		return
	end
	
	local path = inBuffer:String ()
	while path ~= "" do
		local permissionBlockData = inBuffer:String ()
		self.SavedBlocks [path] = permissionBlockData
		
		local node = VFS.Root:GetChildSynchronous (path)
		if node then
			node:GetPermissionBlock ():Deserialize (permissionBlockData)
		end
		
		inBuffer:Char () -- discard newline
		path = inBuffer:String ()
	end
end

function self:Save ()
	self.NeedsSaving = false
	
	local outBuffer = VFS.StringOutBuffer ()
	outBuffer:String ([[

============================================================
Warning: Do not try editing this file without a hex editor.
         You'll probably end up corrupting it.
         
         In fact, you shouldn't even be editing this
         by hand unless you're sure you know what you're
         doing.
============================================================
]])
	outBuffer:UInt32 (self.Version)
	for node, _ in pairs (self.SavableNodes) do
		if not node:GetPermissionBlock ():IsDefault () and
			node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Modify Permissions") then
			self.SavedBlocks [node:GetPath ()] = node:GetPermissionBlock ():Serialize ():GetString ()
		else
			self.SavedBlocks [node:GetPath ()] = nil
		end
	end
	for path, permissionBlockData in pairs (self.SavedBlocks) do
		outBuffer:String (path)
		outBuffer:String (permissionBlockData)
		outBuffer:Char ("\n")
	end
	outBuffer:String ("")
	
	local data = outBuffer:GetString ()
	file.Write ("vfs_" .. (SERVER and "sv" or "cl") .. ".txt", data)
end

function self:SaveNode (node, outBuffer)
	outBuffer:String (node:GetPath ())
	outBuffer:String (node:GetPermissionBlock ():Serialize ())
end

self.NodeCreated            = VFS.NullCallback
self.NodeDeleted            = VFS.NullCallback
self.NodePermissionsChanged = VFS.NullCallback
self.NodeRenamed            = VFS.NullCallback

VFS.PermissionSaver = VFS.PermissionSaver ()