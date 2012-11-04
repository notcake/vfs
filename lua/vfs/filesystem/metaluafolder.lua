local self = {}
VFS.MetaLuaFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.MetaLuaNode)

function self:ctor (path, name, parentFolder)
	self.FolderPath = self:GetPath () == "" and "" or self:GetPath () .. "/"
	
	self.NextCallbackId = 0
	self.ChildrenRequested = false
	self.WaitingForChildren = false
	self.Children = {}
	self.LowercaseChildren = {}
	
	self:AddEventListener ("Renamed", self.Renamed)
end

function self:CreateDirectNode (authId, name, isFolder, callback)
	callback = callback or VFS.NullCallback
	callback (VFS.ReturnCode.AccessDenied)
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	callback (VFS.ReturnCode.AccessDenied)
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	if not potcfileapi then callback (VFS.ReturnCode.AccessDenied) return end
	
	local callbackId = self.NextCallbackId
	self.NextCallbackId = self.NextCallbackId + 1
	self:AddEventListener ("ChildrenReceived", tostring (callbackId),
		function ()
			self:RemoveEventListener ("ChildrenReceived", tostring (callbackId))
			
			for name, node in pairs (self.Children) do
				callback (VFS.ReturnCode.Success, node)
			end
			callback (VFS.ReturnCode.Finished)
		end
	)
	self:RequestChildren ()
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	self:EnsureChildrenReceived (
		function ()
			print ("HAI")
			local lowercaseName = name:lower ()
			if self.Children [name] or self.LowercaseChildren [lowercaseName] then callback (VFS.ReturnCode.Success, self.Children [name] or self.LowercaseChildren [lowercaseName]) return end
			callback (VFS.ReturnCode.NotFound)
		end
	)
end

function self:GetDirectChildSynchronous (name)
	return self.Children [name] or self.LowercaseChildren [name:lower ()]
end

function self:IsCaseSensitive ()
	return false
end

function self:RenameChild (authId, name, newName, callback)
	callback = callback or VFS.NullCallback
	callback (VFS.ReturnCode.AccessDenied)
end

-- Internal, do not call
function self:EnsureChildrenReceived (callback)
	callback = callback or VFS.NullCallback
	if self.ChildrenReceived then
		callback ()
		return
	end
	
	local callbackId = self.NextCallbackId
	self.NextCallbackId = self.NextCallbackId + 1
	self:AddEventListener ("ChildrenReceived", tostring (callbackId),
		function ()
			self:RemoveEventListener ("ChildrenReceived", tostring (callbackId))
			callback ()
		end
	)
	self:RequestChildren ()
end

function self:RequestChildren ()
	if self.WaitingForChildren then return end
	
	self.ChildrenRequested = true
	self.WaitingForChildren = true
	potcfileapi.requestFolderListing (self:GetPath (),
		function (returnCode, folders, files)
			self.WaitingForChildren = false
			
			if not returnCode then
				self:DispatchEvent ("ChildrenReceived")
				return
			end
			
			files   = files   or {}
			folders = folders or {}
			
			-- 1. Produce map of items and new items
			-- 2. Check for deleted items
			-- 2. Check for new folders / files
			-- 3. Call callback
			
			local items = {}
			local new = {}
			
			-- 1. Produce item map
			for _, name in ipairs (folders) do
				if not self.Children [name] and not self.LowercaseChildren [name:lower ()] then
					new [name] = VFS.NodeType.Folder
				end
				items [name] = VFS.NodeType.Folder
			end
			for _, name in ipairs (files) do
				if not self.Children [name] and not self.LowercaseChildren [name:lower ()] then
					new [name] = VFS.NodeType.File
				end
				items [name] = VFS.NodeType.File
			end
			
			-- 2. Check for deleted items
			local deleted = {}
			for name, _ in pairs (self.Children) do
				if not items [name] then
					deleted [name] = true
				end
			end
			for name, _ in pairs (deleted) do
				local node = self.Children [name]
				self.Children [name] = nil
				self.LowercaseChildren [name:lower ()] = nil
				self:DispatchEvent ("NodeDeleted", node)
				node:DispatchEvent ("Deleted")
			end
			
			for name, nodeType in pairs (new) do
				self.Children [name] = (nodeType == VFS.NodeType.Folder and VFS.MetaLuaFolder or VFS.MetaLuaFile) (self.FolderPath .. name, name, self)
				self.LowercaseChildren [name:lower ()] = self.Children [name]
				self:DispatchEvent ("NodeCreated", self.Children [name])
			end
			
			self:DispatchEvent ("ChildrenReceived")
		end
	)
end

-- Events
function self:Renamed ()
	self.FolderPath = self:GetPath () == "" and "" or self:GetPath () .. "/"
end