local Plugin = Plugin

local tgnsMenuDisplayer

function Plugin:Initialise()
	self.Enabled = true
	tgnsMenuDisplayer = TGNSMenuDisplayer.Create(function(menu)
		menu:EditPage("Main", function(x)
			x:AddSideButton("Admin", function()
				TGNS.SendNetworkMessage(self.ADMIN_MENU_REQUESTED, {commandIndex=0, argName="", argValue=""})
			end)
			x:AddPage("Info", "Info", {"Choose an option to learn more about this server, called \"TGNS\"."}, "Main")
			x:EditPage("Info", function(y)
				y:AddSideButton("TGNS Primer", function()
					TGNS.ShowUrl("http://www.tacticalgamer.com/natural-selection-general-discussion/190765-read-sign-tgns-primer-print.html", "TGNS Primer")
				end)
				y:AddSideButton("TGNS Forums", function()
					TGNS.ShowUrl("http://www.tacticalgamer.com/natural-selection/", "http://www.tacticalgamer.com/natural-selection/")
				end)
				y:AddSideButton("Scoreboard Letters", function()
					TGNS.ShowUrl("http://www.tacticalgamer.com/natural-selection-general-discussion/194304-scoreboard-letters-print.html", "Scoreboard Letters")
				end)
				
			end)
			
			x:AddSideButton("Info", function()
				x:SetPage("Info")
			end)
		end)
	end)
	TGNS.HookNetworkMessage(self.MENU_DATA, function(message)
		local argName = message.argName
		local pageId = message.pageId
		local pageName = message.pageName
		local backPageId = message.backPageId
		local chatCmd = message.chatCmd
		local helpText = pageName == "Admin" and "Manage the server according to our rules and tenets. Help in console: sh_help" or string.format("%s%s -- Help in console: sh_help %s", pageName, (TGNS.HasNonEmptyValue(chatCmd) and string.format(" (chat: !%s)", chatCmd) or ""), pageName)
		local buttons = json.decode(message.buttonsJson)
		tgnsMenuDisplayer = TGNSMenuDisplayer.Create(function(menu)
			if backPageId == "" then
				menu:Finish()
			else
				menu:AddPage(pageId, pageName, {helpText}, backPageId)
				menu:EditPage(pageId, function(x)
					TGNS.DoFor(buttons, function(b)
						x:AddSideButton(b.n, function()
							TGNS.SendNetworkMessage(self.ADMIN_MENU_REQUESTED, {commandIndex=b.c, argName=argName, argValue=TGNS.HasNonEmptyValue(b.v) and b.v or b.n})
						end)
					end)
				end)
				menu:SetPage(pageId)
			end
		end)
	end)
	return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end