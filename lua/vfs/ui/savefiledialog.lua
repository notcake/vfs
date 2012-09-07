local self = {}

function self:Init ()
	self:SetTitle ("Save as...")
	self:SetVerb ("Save")
	
	self:SetFileMustExist (false)
end

vgui.Register ("VFSSaveFileDialog", self, "VFSFileDialog")

--- Displays a file selection dialog.
-- @param callback A callback function taking a path and its corresponding IFile if it exists.
function VFS.OpenSaveFileDialog (callback)
	local dialog = vgui.Create ("VFSSaveFileDialog")
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	dialog:SelectAll ()
	
	return dialog
end