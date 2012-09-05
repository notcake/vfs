local self = {}

function self:Init ()
	self:SetTitle ("Open...")
	
	self:SetFileMustExist (true)
end

vgui.Register ("VFSOpenFileDialog", self, "VFSFileDialog")

function VFS.OpenOpenFileDialog (callback)
	local dialog = vgui.Create ("VFSOpenFileDialog")
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	dialog:SelectAll ()
	
	return dialog
end