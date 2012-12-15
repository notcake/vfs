if CLIENT and not file.Exists ("vfs/vfs.lua", "LCL") then return end
if CLIENT and not GetConVar ("sv_allowcslua"):GetBool () then return end
include ("vfs/vfs.lua")