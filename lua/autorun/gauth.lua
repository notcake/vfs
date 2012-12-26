if SERVER or
   file.Exists ("gauth/gauth.lua", "LUA") or
   file.Exists ("gauth/gauth.lua", "LCL") and GetConVar ("sv_allowcslua"):GetBool () then
	include ("gauth/gauth.lua")
end