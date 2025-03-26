-- Permissions Configuration
-- These permissions are checked against Player.group from RedEM.GetPlayer(source)
-- Example usage in server.lua:
-- local Player = RedEM.GetPlayer(source)
-- if table.contains(qadr_pass_settings.permissions["addpass"], Player.group) then
--     -- Player has permission
-- end
qadr_pass_settings = {
	defaultlang = "en", -- Sets the default language to English.
	translations = {}, -- An empty table for storing translations. Do not modify this directly. (do not touch)
    permissions = {
        ["addpass"] = {
            "admin",
            "user",
            "moderator",
            "owner"
        },
        ["removepass"] = {
            "admin",
            "owner"
        },
        ["givepass"] = {
            "admin",
            "moderator",
            "owner"
        },
        ["checkpass"] = {
            "user",
            "admin",
            "moderator",
            "owner",
            "helper"
        }
    }
}