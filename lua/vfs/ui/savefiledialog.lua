local self = {}

function self:Init ()
	self:SetTitle ("Save as...")
	
	self:SetFileMustExist (false)
end

vgui.Register ("VFSSaveFileDialog", self, "VFSFileDialog")

function VFS.OpenSaveFileDialog (callback)
	local dialog = vgui.Create ("VFSSaveFileDialog")
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	dialog:SelectAll ()
	
	return dialog
end