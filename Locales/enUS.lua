local L = LibStub("AceLocale-3.0"):NewLocale("HuokanAdvertiserTools", "enUS", true)
if not L then return end

L.addon_name = "Huokan Advertiser Tools"
L.profiles = "Profiles"
L.help = "Help"
L.locked_size = "Locked Size"
L.locked_size_desc = "This will prevent the frame from being resized. Ensure the size is set as you want it before enabling this option."
L.open = "Open"
L.auto_show = "Auto Show"
L.auto_hide = "Auto Hide"
L.help_desc = [[

/hat help - Show help
/hat options - Open options
/hat version - Check what version of Huokan Advertiser Tools is installed
/hat guildbank - Show guild bank deposit log
/hat trade - Show the trade log
/hat goldtracker - Show the gold tracker
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
L.update_available_with_version = "A newer version of Huokan Advertiser Tools (%s) is available. You are using %s."
-- Trade module
L.trade = "Trade"
L.trades_for_user = "%s's Trades"
L.traded_money_to = "%s gave %s to %s."
-- Not in Community Guild module
L.warning_not_in_community_guild = "WARNING: You are not in a Huokan Community guild. You must join a Huokan Community guild in order for the addon to function."
-- Gold Tracker module
L.gold_tracker = "Gold Tracker"
L.total_amount = "Total: %s"
L.include_guild_banks_if_guild_leader = "Include guild banks in gold totals if you're the GM"
L.confirm_delete_character_from_gold_tracker = "Are you sure you want to remove %s from the gold tracker?"
