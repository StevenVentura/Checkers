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
isHostingTheCheckersGame = false;
doTheyAlsoHaveTheAddon = -555;
local MODE_WAITING_FOR_REQUESTS = 0;
local MODE_WAITING_FOR_ACCEPT = 1;
local MODE_ANSWERING_REQUEST = 2;
local MODE_PLAYING = 3;
local pieces = {};--holds the data for each checker
local TEAM_HOST = 0;--for checker pieces
local TEAM_GUEST = 1;
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

local function killPiece(index)
pieces[index].alive = false;
pieces[index].checkerFrame:Hide();
end--end function killPiece



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
isHostingTheCheckersGame = true;
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
if (checkersMode ~= MODE_PLAYING) then return end;-- so no interference
backgroundFrame:Hide();
reply(CHECKERS_LEAVING_MESSAGE);
print("|cff8888ff[Checkers] Game over. User left the game.");
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end--end local function leaveTheGame


function CheckersIncoming(ChatFrameSelf, event, message, author, ...)
local sarray = checkersSplitString(message);
--[[
turnUpdateMessage:
>CHECKERS update moveIndex r2 c2 removedIndex turnEnded
1         2      3         4  5  6            7
const     const  i         i  i  i (-1)       i 0 or 1
--]]
if (sarray[2] == "update") then
local moveIndex, r2, c2, removedIndex, turnEnded = 
	tonumber(sarray[3]), tonumber(sarray[4]), tonumber(sarray[5]), 
	tonumber(sarray[6]), tonumber(sarray[7]);

--edit the checker data and frame
pieces[moveIndex].row = r2;
pieces[moveIndex].column = c2;
pieces[moveIndex].checkerFrame:
pieces[moveIndex].checkerFrame:ClearAllPoints();
pieces[moveIndex].checkerFrame:SetPoint("BOTTOMLEFT",
convertColumnToX(pieces[moveIndex].column),convertRowToY(pieces[moveIndex].row));
if (removedIndex ~= -1) then
--kill the piece
killPiece(pieces[removedIndex]);
end--end something was removed
--handle turn


end--end update
if (message == CHECKERS_ACCEPT_REQUEST_MESSAGE) then
startCheckers();

end--end message = CHECKERS_ACCEPT_REQUEST_MESSAGE
if (message == CHECKERS_REQUEST_MESSAGE and checkersMode == MODE_WAITING_FOR_REQUESTS) then
otherPlayer = author;

isHostingTheCheckersGame = false;
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
otherPlayer = author;
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

local function getRow(y)--y must be relative to the board bottomleft
return math.floor(y / (heightB/8)) + 1;
end--end function getRow
local function getColumn(x)--x must be relative to the board bottomleft
return math.floor(x / (widthB/8)) + 1;
end--end function getColumn
local function convertRowToY(row)
return heightB/8 * (row-1);
end
local function convertColumnToX(column)
return widthB/8 * (column-1);
end

--returns either an index, or -1 if nothing 
local function isSpaceOccupied(row,column)
local kids = {backgroundFrame:GetChildren()};

for _,checker in ipairs(kids) do
local name = checker:GetName();
--make sure it is actually a checker
if (string.sub(name,1,strlen("checkerFrame")) == "checkerFrame")
then
--get the number at the end. This corresponds to its location in pieces[][] array.
local index = tonumber(string.sub(name,strlen("checkerFrame")+1));
if (pieces[index].row and pieces[index].row==row
	and pieces[index].column == column and pieces[index].alive == true) then
return index;
end
end--end if is checker
end--end for
return -1;

end
--[[
function isValidMove
returns booleanValid [, takenPieceIndex]
--]]
local function isValidMove(r1, c1, r2, c2, team, king)
--check board boundaries
if (r2 <= 0 or r2 >= 9 or c2 <= 0 or c2 >= 9) then
return false;
end--end out of board bounds
--check if r2,c2 is occupied
if (isSpaceOccupied(r2,c2) ~= -1) then
return false;
end
--check legal diagonal single move for non-king
if (team == TEAM_HOST) then
if (r2 == r1 + 1 and (c2 == c1 + 1 or c2 == c1 - 1))
then
return true;
end--end diagonal forward by host
else--else team == TEAM_GUEST, non-king
if (r2 == r1 - 1 and (c2 == c1 + 1 or c2 == c1 - 1))
then
return true;
end--end if
end--end not-host-else

--check legal diagonal singal move for king
if (king == true)
then
if (r2 == r1 + 1 and (c2 == c1 + 1 or c2 == c1 - 1))
	or
(r2 == r1 - 1 and (c2 == c1 + 1 or c2 == c1 - 1)) then
return true;
end--end if
end--end king == true

--check legal piece-take-move for non-king
if (team == TEAM_HOST) then
if (r2 == r1 + 2 and (c2 == c1 + 2 or c2 == c1 - 2)
	and isSpaceOccupied((r2+r1)/2,(c2+c1)/2) ~= -1)
then
print("okay?");
return true, isSpaceOccupied((r2+r1)/2,(c2+c1)/2);
end--end piece take by host
else--else team == TEAM_GUEST, non-king
if (r2 == r1 - 2 and (c2 == c1 + 2 or c2 == c1 - 2)
	and isSpaceOccupied((r2+r1)/2,(c2+c1)/2) ~= -1)
then
return true, isSpaceOccupied((r2+r1)/2,(c2+c1)/2);
end--end if
end--end not-host-else

--check legal piece-take-move for king
if ((r2 == r1 + 2 or r2 == r1 - 2) and (c2 == c1 + 2 or c2 == c1 - 2)
	and isSpaceOccupied((r2+r1)/2,(c2+c1)/2) ~= -1)
then
return true, isSpaceOccupied((r2+r1)/2,(c2+c1)/2);
end--end piece take by host


return false;--default case
end--end isValidMove



local function createPieces()
local r,c = 1,2;
local t = TEAM_HOST;
for i = 1, 24 do 
pieces[i] = {
row = r;--row 1 is the bottom row.
column = c;
team = t;
king = false;
alive = true;
checkerFrame = CreateFrame("FRAME", "checkerFrame" .. i, backgroundFrame);
};
if ((isHostingTheCheckersGame==true and pieces[i].team == TEAM_HOST) or 
	(isHostingTheCheckersGame==false and pieces[i].team == TEAM_GUEST)) then
pieces[i].checkerFrame:SetMovable(true);
pieces[i].checkerFrame:EnableMouse(true);
pieces[i].checkerFrame:RegisterForDrag("LeftButton");
pieces[i].checkerFrame:SetScript("OnDragStart",pieces[i].checkerFrame.StartMoving);
pieces[i].checkerFrame:SetScript("OnDragStop", function(self)
self:StopMovingOrSizing();
local x, y = self:GetLeft(), self:GetBottom();
--make x and y relative to the checker board rather than absolute.
x = x - backgroundFrame:GetLeft();
y = y - backgroundFrame:GetBottom();
--make x and y be the middle of the checker piece.
x = x + widthB/8 / 2;
y = y + widthB/8 / 2;
--make sure checkers piece lands on a valid tile.
local landedRow, landedColumn = getRow(y), getColumn(x);
--board piece move logic!
isValid, takenIndex = isValidMove(pieces[i].row,pieces[i].column,landedRow,landedColumn,
		pieces[i].team,pieces[i].king);
if (isValid)
		then
		--this will be done on the other players machine too via socket message
		pieces[i].row = landedRow;
		pieces[i].column = landedColumn;
		--check if a piece was taken
		if (takenIndex and takenIndex ~= -1)
		then
		killPiece(takenIndex);
		end--end taken
		--broadcast the move via turnUpdateMessage
		reply(">CHECKERS update " .. i .. " " .. landedRow .. " " ..
					landedColumn .. " " .. takenIndex .. " " .. 1);
		else
		--was not a valid move -- put it back!
		end
		pieces[i].checkerFrame:ClearAllPoints();
		pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",convertColumnToX(pieces[i].column),
				convertRowToY(pieces[i].row));
end); 
end--end isOneOfMyPiecesSoLetMeMoveIt
pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",(c-1)*widthB/8,(r-1)*heightB/8);
pieces[i].checkerFrame:SetSize(widthB/8,heightB/8);
local tx = pieces[i].checkerFrame:CreateTexture();
tx:SetAllPoints();
tx:SetAlpha(1);
tx:SetTexture('Interface/AddOns/Checkers/images/checkers_background.tga');
pieces[i].checkerFrame:Show();

c = c + 2;
if (c > 8) then r = r + 1; 
if (r == 4) then
r = 6;--skip to other side
t = TEAM_GUEST;--change faction of pieces here
end--end r == 4
if (c == 9) then
c = 2;
else
c = 1;
end--end c == 9
end--end if c > 8
end--end for


end--end function createPieces



function startCheckers()
setCheckersMode(MODE_PLAYING);
createPieces();
--draw the frames
popframe:Hide();
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



