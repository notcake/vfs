VFS.Root:CreateFolder (GAuth.GetSystemId (), "Super Admins",
	function (returnCode, folder)
		folder:SetDeletable (false)
		folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Read",        GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "View Folder", GAuth.Access.Allow)
	end
)