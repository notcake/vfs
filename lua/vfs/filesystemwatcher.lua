local self = {}
VFS.FileSystemWatcher = VFS.MakeConstructor (self)

--[[
	Events:
		Changed (IFile file)
			Fired when a file has been modified.
]]

function self:ctor ()
	self.Files   = {}
	self.Folders = {}
	
	VFS.EventProvider (self)
	
	VFS:AddEventListener ("Unloaded", "VFS.FileSystemWatcher." .. tostring (self),
		function ()
			self:dtor ()
		end
	)
	timer.Create ("VFS.FileSystemWatcher." .. tostring (self), 10, 0,
		function ()
			self:CheckFileTimes ()
		end
	)
end

function self:dtor ()
	VFS:RemoveEventListener ("Unloaded", "VFS.FileSystemWatcher." .. tostring (self))
	timer.Destroy ("VFS.FileSystemWatcher." .. tostring (self))
	
	self:Clear ()
end

function self:AddFile (file)
	if not file then return end
	if self.Files [file] then return end
	
	self.Files [file] = true
	self:HookFile (file)
end

function self:AddFolder (folder)
	if not folder then return end
	if self.Folders [folder] then return end
	
	self.Folders [folder] = true
	self:HookFolder (folder)
end

function self:Clear ()
	for file, _ in pairs (self.Files) do
		self:UnhookFile (file)
	end
	for folder, _ in pairs (self.Folders) do
		self:UnhookFolder (folder)
	end
	self.Files   = {}
	self.Folders = {}
end

function self:RemoveFile (file)
	if not self.Files [file] then return end
	
	self.Files [file] = nil
	self:UnhookFile (file)
end

function self:RemoveFolder (folder)
	if not self.Folders [folder] then return end
	
	self.Folders [folder] = nil
	self:UnhookFolder (folder)
end

-- Internal, do not call
function self:CheckFileTimes ()
	-- Poll the modification time and file size of real files to
	-- cause them to fire their Updated event on modifications.
	for file, _ in pairs (self.Files) do
		file:GetModificationTime ()
		file:GetSize ()
	end
end

function self:HookFile (file)
	if not file then return end
	
	file:AddEventListener ("Updated", "VFS.FileSystemWatcher." .. tostring (self),
		function (node, updateFlags)
			self:DispatchEvent ("Changed", node)
		end
	)
end

function self:UnhookFile (file)
	if not file then return end
	
	file:RemoveEventListener ("Updated", "VFS.FileSystemWatcher." .. tostring (self))
end

function self:HookFolder (folder)
	if not folder then return end
	
	folder:AddEventListener ("NodeUpdated", "VFS.FileSystemWatcher." .. tostring (self),
		function (_, node, updateFlags)
			self:DispatchEvent ("Changed", node)
		end
	)
end

function self:UnhookFolder (folder)
	if not folder then return end
	
	folder:RemoveEventListener ("NodeUpdated", "VFS.FileSystemWatcher." .. tostring (self))
end