local lan = GetConVar("sv_lan")
if lan:GetBool() then SetGlobalBool("gprofiler_lan", true) end