if CLIENT and not file.Exists ("gauth/gauth.lua", "LCL") then return end
if CLIENT and not GetConVar ("sv_allowcslua"):GetBool () then return end
include ("gauth/gauth.lua")