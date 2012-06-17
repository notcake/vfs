GLib.String = {}

function Glib.String.ConsoleEscape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.ConsoleEscape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\q")
		:gsub ("\'", "\\s")
end

function GLib.String.Escape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.Escape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\\"")
		:gsub ("\'", "\\\'")
end