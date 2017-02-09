--[[
Addon created by Steven Ventura (aka noob)
All rights reserved
kek
work started on 1/2/16
The purpose of this addon is to create a turn-based game of Checkers, Following
	Traditional Checkers rules.
--]]

SLASH_CHECKERS1 = "/checkers"; SLASH_CHECKERS2 = "/checker";--for illiterates
SlashCmdList["CHECKERS"] = slashCheckers;
local otherPlayer = "";
local isHostingTheGame = false;
doTheyAlsoHaveTheAddon = -555;
local MODE_WAITING_FOR_REQUESTS = 0;
local MODE_WAITING_FOR_ACCEPT = 1;
local MODE_ANSWERING_REQUEST = 2;
local MODE_PLAYING = 3;


Checkers_eventFrame = CreateFrame("Frame");
Checkers_eventFrame:SetScript("OnUpdate", function(self, elapsed) Checkers_OnUpdate(self, elapsed) end)

function reply(text)
SendChatMessage(text,"WHISPER",nil,otherPlayer);
end--end function reply

function slashCheckers()
print("slash checkers responds");
function slashPong(msg, editBox)
local command, rest = msg:match("^(%S*)%s*(.-)$");
local targetName = "Steven";--placeholder
if (command == "") then
targetName = GetUnitName("target",true);
else
targetName = command;
print(targetName);
end
if targetName and checkersMode == MODE_WAITING_FOR_REQUESTS and targetName ~= GetUnitName("player",true)
 then 
print("|cff8888ff[Checkers] Sending game request to " .. targetName .. " . . .");
reply(CHECKERS_REQUEST_MESSAGE,targetName) 
doTheyAlsoHaveTheAddon = 0;--begin timer
isHostingTheGame = true;
otherPlayer = targetName;
 end--end valid request
if targetName == nil or targetName == GetUnitName("player",true)
 then
print("|cff8888ff[Checkers] Target another player, then type |cffffffff/Checkers|cff8888ff, Or type |cffffffff/Checkers playername|cff8888ff.");
 end--end targeted self
end--end function slashPong

end--end function slashCheckers



function Checkers_initialize()
end--end Checkers_initialize




local function handleDoTheyAlsoHaveTheAddon(elapsed)
if (doTheyAlsoHaveTheAddon == -555) then return end;
doTheyAlsoHaveTheAddon = doTheyAlsoHaveTheAddon + elapsed;
if (doTheyAlsoHaveTheAddon > 8.88) then
print("|cff8888ff[Pong] |cffff6666" .. sentPongRequestTo .. " does not have the Pong addon. |cffddddddTell them to download it from |cffffff00www.curse.com/addons/wow/Pong |cff8888ffso they can play with you!")
doTheyAlsoHaveTheAddon = -555;
end--end they dont :-(

end--end function doTheyAlsoHaveTheAddon

function Pong_OnUpdate(self, elapsed)
handleDoTheyAlsoHaveTheAddon(elapsed);


end--end onupdate

function CheckersIncoming(ChatFrameSelf, event, message, author, ...)


end--end function CheckersIncoming
function CheckersOutgoing(ChatFrameSelf, event, message, author, ...)


end--end function CheckersOutgoing

function Checkers_OnLoad()
print("|cff8888ff[Checkers] addon loaded! Type '/Checkers' while targeting a player to play against them. They must also have the addon: |cffffff00www.curse.com/addons/wow/checkers");
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",CheckersIncoming);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CheckersOutgoing);
end--end Checkers_OnLoad



