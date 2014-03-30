local self = {}
GAuth.PermissionDictionary = GAuth.MakeConstructor (self)

function self:ctor (name)
	self.Permissions = {}
	self.Name = name or "Unknown"
	
	self:AddPermission ("Modify Permissions")
	self:AddPermission ("Set Owner")
end

function self:AddPermission (actionId)
	self.Permissions [actionId] = true
end

function self:GetPermissionEnumerator ()
	return GLib.KeyEnumerator (self.Permissions)
end

function self:PermissionExists (actionId)
	return self.Permissions [actionId] and true or false
end

function self:RemovePermission (actionId)
	self.Permissions [actionId] = false
end