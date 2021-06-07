local L = LibStub("AceLocale-3.0"):NewLocale("HuokanAdvertiserTools", "enUS", true)
if not L then return end

L.addon_name = "Huokan Advertiser Tools"
L.profiles = "Profiles"
L.help = "Help"
L.locked = "Locked"
L.auto_show = "Auto Show"
L.auto_hide = "Auto Hide"
L.help_desc = [[

/hat help - Show help
/hat options - Open options
/hat version - Check what version of Huokan Advertiser Tools is installed
/hat guildbank - Show guild bank deposit log
/hat guildbank resetui - Reset the position of the guild bank deposit log UI to the center of the screen
]]
-- GuildBank module
L.guild_bank = "Guild Bank"
L.huokan_bank_deposits_for_user = "%s's Huokan Bank Deposits"
L.deposit_timed_out = "Guild bank deposit timed out."
L.failed_to_verify_gold_change = "Failed to verify gold change."
L.failed_to_verify_deposit = "Failed to verify deposit."
L.guild_bank_deposit = "%s was deposited into %s by %s."
L.note = "Note"
-- VersionCheck module
L.version = "Version %s (%d)"
L.update_available = "A newer version of Huokan Advertiser Tools is available."
