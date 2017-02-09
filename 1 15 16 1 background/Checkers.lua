--[[
Addon created by Steven Ventura (aka noob)
All rights reserved
kek / zozzle
work started on 1/2/16
The purpose of this addon is to create a turn-based game of Checkers, Following
	Traditional Checkers rules.
--]]

SLASH_CHECKERS1 = "/checkers"; SLASH_CHECKERS2 = "/checker";--for illiterates
SlashCmdList["CHECKERS"] = slashCheckers;
local CHECKERS_REQUEST_MESSAGE = ">CHECKERS Hey I want to play Checkers with you, but it appears you do not have the Addon, or it is disabled. You can get it from Curse.com/addons/wow/Checkers !! go download it to play with me!";
local CHECKERS_REQUEST_ACKNOWLEDGED = ">CHECKERS !hold on leme think bout it m8!";
local CHECKERS_ACCEPT_REQUEST_MESSAGE = ">CHECKERS !Yes, i'd love to play, that game is 8/8 m8!";
local CHECKERS_DECLINE_REQUEST_MESSAGE = ">CHECKERS !No, im too busy with other stuff m8 sorry :-(!";
local CHECKERS_LEAVING_MESSAGE = '>CHECKERS !BYE BYE!';
local otherPlayer = "steven";
local heightB = 600;
local widthB = heightB;--square board.
local isHostingTheGame = false;
doTheyAlsoHaveTheAddon = -555;
local MODE_WAITING_FOR_REQUESTS = 0;
local MODE_WAITING_FOR_ACCEPT = 1;
local MODE_ANSWERING_REQUEST = 2;
local MODE_PLAYING = 3;
checkersMode = MODE_WAITING_FOR_REQUESTS;

local keyStrokes = CreateFrame("Frame",'keyStrokes',UIParent);
local popframe = CreateFrame('Frame','popframe',UIParent);

local backgroundFrame = CreateFrame('Frame','backgroundFrame',UIParent);
tex = backgroundFrame:CreateTexture();
tex:SetAllPoints();
tex:SetAlpha(1);
tex:SetTexture('Interface/AddOns/Checkers/images/checkers_background.tga');


Checkers_eventFrame = CreateFrame("Frame");
Checkers_eventFrame:SetScript("OnUpdate", function(self, elapsed) Checkers_OnUpdate(self, elapsed) end)

--local function taken from http://stackoverflow.com/questions/1426954/split-string-in-lua by user973713 on 11/26/15
function checkersSplitString(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; local i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end


local function reply(text)
SendChatMessage(text,"WHISPER",nil,otherPlayer);
end--end local function reply

function slashCheckers(msg, editBox)
local command, rest = msg:match("^(%S*)%s*(.-)$");
local targetName = "";
if (command == "") then
targetName = GetUnitName("target",true);
else
targetName = command;
if (not UnitExists(targetName) ) then 
print("|cff8888ff[Checkers] " .. targetName .. " does not exist. Make sure you type a dash and then their server name, if they are on another server.");
targetName = nil;
return;--special case. return.
end--end not exist
end--end manual
if targetName and checkersMode == MODE_WAITING_FOR_REQUESTS and targetName ~= GetUnitName("player",true)
 then 
print("|cff8888ff[Checkers] Sending game request to " .. targetName .. " . . .");
doTheyAlsoHaveTheAddon = 0;--begin timer
isHostingTheGame = true;
otherPlayer = targetName;
reply(CHECKERS_REQUEST_MESSAGE);
 end--end valid request
if targetName == nil or targetName == GetUnitName("player",true)
 then
print("|cff8888ff[Checkers] Target another player, then type |cffffffff/Checkers|cff8888ff, Or type |cffffffff/Checkers playername|cff8888ff.");
 end--end targeted self

end--end local function slashCheckers

local function setCheckersMode(mode)
checkersMode = mode;

end--end local function setCheckersMode

local function putConfirmationBox()
popframe:SetPoint('CENTER',0,125)
local tex = popframe:CreateTexture("ARTWORK");
tex:SetAllPoints();
tex:SetTexture(0.1686274509803922,0.0588235294117647,0.003921568627451); tex:SetAlpha(0.80);
 titleText = popframe:CreateFontString("titleText",popframe,"GameFontNormal");
 titleText:SetTextColor(1,0.643,0.169,1);
 titleText:SetShadowColor(0,0,0,1);
 titleText:SetShadowOffset(2,-1);
 titleText:SetPoint("TOPLEFT",tex,"TOPLEFT",0,0);
titleText:SetText("/checkers play " .. otherPlayer .. "?");
titleText:Show();
popframe:SetFrameStrata('HIGH');
popframe:SetSize(200,22*2+13);
popframe:Show();
end-- end local function putConfirmationBox





local function handleDoTheyAlsoHaveTheAddon(elapsed)
if (doTheyAlsoHaveTheAddon == -555) then return end;
doTheyAlsoHaveTheAddon = doTheyAlsoHaveTheAddon + elapsed;
if (doTheyAlsoHaveTheAddon > 8.88) then
print("|cff8888ff[Checkers] |cffff6666" .. otherPlayer .. " does not have the Checkers addon. |cffddddddTell them to download it from |cffffff00www.curse.com/addons/wow/Checkers |cff8888ffso they can play with you!")
doTheyAlsoHaveTheAddon = -555;
end--end they dont :-(

end--end local function doTheyAlsoHaveTheAddon

function Checkers_OnUpdate(self, elapsed)
handleDoTheyAlsoHaveTheAddon(elapsed);


end--end onupdate

local function leaveTheGame()
if (checkersMode ~= MODE_PLAYING) then return end;
keyStrokes:Hide();
reply(CHECKERS_LEAVING_MESSAGE);
print("|cff8888ff[Checkers] Game over. User left the game.");
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end--end local function leaveTheGame


function CheckersIncoming(ChatFrameSelf, event, message, author, ...)
local sarray = checkersSplitString(message);
--[[
turnUpdateMessage:
>CHECKERS update x1 y1 x2 y2 removedX removedY turnEnded
1         2      3  4  5  6  7        8        9
const     const  i  i  i  i  i        i        bool
--]]
if (message == CHECKERS_REQUEST_MESSAGE and checkersMode == MODE_WAITING_FOR_REQUESTS) then
otherPlayer = author;
isHostingTheGame = false;
reply(CHECKERS_REQUEST_ACKNOWLEDGED);
setCheckersMode(MODE_ANSWERING_REQUEST);
putConfirmationBox();
end--end request message
if (message == CHECKERS_LEAVING_MESSAGE) then
leaveTheGame();
end--end leaving
if (message == CHECKERS_DECLINE_REQUEST_MESSAGE) then
print("|cff8888ff[Checkers] " .. author .. " declined your invitation to play. What a jerk!");
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end
if (message == CHECKERS_REQUEST_ACKNOWLEDGED and doTheyAlsoHaveTheAddon ~= -555) then
print("|cff8888ff[Checkers] " .. author .. " has the addon! Waiting for their response now...");
doTheyAlsoHaveTheAddon = -555;
end


--near end of function. dont put stuff below this.
if (sarray[1] == ">CHECKERS") then
return true;
end
return false;
end--end local function CheckersIncoming
function CheckersOutgoing(ChatFrameSelf, event, message, author, ...)
local sarray = checkersSplitString(message);
if (sarray[1] == ">CHECKERS") then
return true;
end
return false;

end--end local function CheckersOutgoing
function startCheckers()
--draw the frames
backgroundFrame:SetPoint("CENTER",0,0);
backgroundFrame:SetSize(widthB,heightB);
backgroundFrame:SetFrameStrata('MEDIUM');
backgroundFrame:Show(); 


end--end function startCheckers

local function acceptButtonPressed()
reply(CHECKERS_ACCEPT_REQUEST_MESSAGE);
setCheckersMode(MODE_PLAYING);
startCheckers();
end


local function declineButtonPressed()
reply(CHECKERS_DECLINE_REQUEST_MESSAGE);
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end


function Checkers_initialize()--called from the XML
local acceptFrame = CreateFrame("Button", "acceptFrame", popframe, "UIPanelButtonTemplate");
acceptFrame:SetText("Accept Game");
acceptFrame:SetPoint("TOPLEFT",0,-13);
acceptFrame:SetWidth(108);
acceptFrame:SetHeight(22);
acceptFrame:SetScript("OnClick", acceptButtonPressed);
acceptFrame:SetBackdropBorderColor(0,0,1);--include alpha?
acceptFrame:SetBackdropColor(0,0,1);
acceptFrame:Show();
local declineFrame = CreateFrame("Button", "declineFrame", popframe, "UIPanelButtonTemplate");
declineFrame:SetText("Decline Game");
declineFrame:SetPoint("TOPLEFT",acceptFrame,"BOTTOMLEFT",0,0);
declineFrame:SetWidth(108);
declineFrame:SetHeight(22);
declineFrame:SetScript("OnClick", declineButtonPressed);
declineFrame:SetBackdropBorderColor(0,0,1);--include alpha?
declineFrame:SetBackdropColor(0,0,1);
declineFrame:Show();
local exitCheckersFrame = CreateFrame("Button", "exitCheckersFrame", backgroundFrame, "UIPanelButtonTemplate");
exitCheckersFrame:SetText("x");
exitCheckersFrame:SetPoint("TOPRIGHT",0,0);
exitCheckersFrame:SetSize(24,24);
exitCheckersFrame:SetScript("OnClick", leaveTheGame);
exitCheckersFrame:SetBackdropColor(0,0,1);
exitCheckersFrame:Show();
end--end Checkers_initialize

function Checkers_OnLoad()
print("|cff8888ff[Checkers] addon loaded! Type '/Checkers' while targeting a player to play against them. They must also have the addon: |cffffff00www.curse.com/addons/wow/checkers");
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",CheckersIncoming);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CheckersOutgoing);
end--end Checkers_OnLoad



