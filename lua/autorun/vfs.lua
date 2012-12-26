if SERVER or
   file.Exists ("vfs/vfs.lua", "LUA") or
   file.Exists ("vfs/vfs.lua", "LCL") and GetConVar ("sv_allowcslua"):GetBool () then
	include ("vfs/vfs.lua")
end