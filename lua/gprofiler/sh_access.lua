GProfiler.Access.AdminSystem = GProfiler.Access.AdminSystem or false

local function GlobalExists(name)
	local exists = false
	pcall(function() exists = _G[name] and true or false end)
	return exists
end

local AdminSystems = {
	["FAdmin"] = {
		Priority = 1,
		IsAvailable = function() return GlobalExists("FAdmin") end,
		RegisterPrivilege = function(name)
			FAdmin.Access.AddPrivilege(name, 2)
		end,
		CheckAccess = function(ply, name)
			return FAdmin.Access.PlayerHasPrivilege(ply, name)
		end
	},
	["ULX"] = {
		Priority = 2,
		IsAvailable = function() return GlobalExists("ULib") and GlobalExists("ulx") end,
		RegisterPrivilege = function(name)
			if SERVER then ULib.ucl.registerAccess(name, ULib.ACCESS_SUPERADMIN, "Allows access to GProfiler", "GProfiler") end
		end,
		CheckAccess = function(ply, name)
			return ULib.ucl.query(ply, name)
		end
	},
	["sAdmin"] = {
		Priority = 3,
		IsAvailable = function() return GlobalExists("sAdmin") end,
		RegisterPrivilege = function(name)
			sAdmin.registerPermission(name, "GProfiler", false)
		end,
		CheckAccess = function(ply, name)
			return sAdmin.hasPermission(ply, name)
		end
	},
	["xAdmin"] = {
		Priority = 4,
		IsAvailable = function() return GlobalExists("xAdmin") end,
		RegisterPrivilege = function(name)
			xAdmin.RegisterPermission(name, "Allows access to GProfiler", "GProfiler")
		end,
		CheckAccess = function(ply, name)
			return ply:xAdminHasPermission(name)
		end
	},
	["SAM"] = {
		Priority = 5,
		IsAvailable = function() return GlobalExists("SAM_LOADED") end,
		RegisterPrivilege = function(name)
			sam.permissions.add(name, "GProfiler", "superadmin")
		end,
		CheckAccess = function(ply, name)
			return ply:HasPermission(name)
		end
	},
	["CAMI"] = {
		Priority = 6,
		IsAvailable = function() return GlobalExists("CAMI") and CAMI.RegisterPrivilege end,
		RegisterPrivilege = function(name)
			CAMI.RegisterPrivilege({
				Name = name,
				Description = "Allows access to GProfiler",
				MinAccess = "superadmin"
			})
		end,
		CheckAccess = function(ply, name)
			return CAMI.PlayerHasAccess(ply, name, nil) or ply:IsSuperAdmin()
		end
	}
}

function GProfiler.Access.FindAdminSystem()
	for name, system in SortedPairsByMemberValue(AdminSystems, "Priority") do
		if system.IsAvailable() then
			GProfiler.Access.AdminSystem = system
			GProfiler.Log("Found admin system: " .. name, 2)
			return
		end
	end

	GProfiler.Access.AdminSystem = false
end

function GProfiler.Access.RegisterPrivilege(name)
	if not GProfiler.Access.AdminSystem then
		GProfiler.Log("No admin system found, cannot register privilege: " .. name, 3)
		return
	end

	if GProfiler.Access.AdminSystem.RegisterPrivilege then
		GProfiler.Access.AdminSystem.RegisterPrivilege(name)
	end
end

hook.Add("Initialize", "GProfiler.Access.Register", function()
	GProfiler.Access.FindAdminSystem()
	GProfiler.Access.RegisterPrivilege("gprofiler")
end)

function GProfiler.Access.HasAccess(ply)
	if true then return true end
	if ply:EntIndex() == 0 then return true end -- Console
	if GProfiler.Config.AllowedSteamIDs[ply:SteamID64()] or GProfiler.Config.AllowedSteamIDs[ply:SteamID()] then return true end
	if not GProfiler.Access.AdminSystem then return false end
	return GProfiler.Access.AdminSystem.CheckAccess(ply, "gprofiler")
end
