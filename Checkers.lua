--[[
Addon created by Steven Ventura (aka noob)
All rights reserved
kek / zozzle
work started on 1/2/16
The purpose of this addon is to create a turn-based game of Checkers, Following
	Traditional Checkers rules.
	
9/6/17 adding chess into this addon
--]]

SLASH_CHECKERS1 = "/checkers"; SLASH_CHECKERS2 = "/checker";--for illiterates
SlashCmdList["CHECKERS"] = slashCheckers;
SLASH_CHESS1 = "/chess";
SlashCmdList["CHESS"] = slashChess;
local CHECKERS_REQUEST_MESSAGE = ">CHECKERS Hey I want to play Checkers with you, but it appears you do not have the Addon, or it is disabled. You can get it from Curse.com/addons/wow/Checkers !! go download it to play with me!";
local CHESS_REQUEST_MESSAGE = ">CHESS Hey I want to play Chess with you, but you don't have the addon. You can get it from Curse.com/addons/wow/Checkers !! the download includes both checkers and chess as 1 addon";

local CHECKERS_REQUEST_ACKNOWLEDGED = ">CHECKERS !hold on leme think bout it m8!";
local CHECKERS_ACCEPT_REQUEST_MESSAGE = ">CHECKERS !Yes, i'd love to play, that game is 8/8 m8!";
local CHECKERS_DECLINE_REQUEST_MESSAGE = ">CHECKERS !No, im too busy with other stuff m8 sorry :-(!";
local CHECKERS_LEAVING_MESSAGE = '>CHECKERS !BYE BYE!';
checkersOpponentName = "Invalid Name";
local heightB = 500;
local widthB = heightB;--square board.
local widthB_DEFAULT = 500;
iAmAskingForChessNotCheckers = false;
isPlayingChess = false;
isHostingTheCheckersGame = false;
doTheyAlsoHaveTheAddon = -555;
isMyCheckersTurn = false;
isAPieceTakeTurn = false;
local MODE_WAITING_FOR_REQUESTS = 0;
local MODE_WAITING_FOR_ACCEPT = 1;
local MODE_ANSWERING_REQUEST = 2;
local MODE_PLAYING = 3;

local VOICE_WRONG_TURN = "VOICE_WRONG_TURN";
local VOICE_INVALID_MOVE = "VOICE_INVALID_MOVE";
local VOICE_FRIENDLY_PIECE_TAKEN = "VOICE_FRIENDLY_PIECE_TAKEN";
local VOICE_ENEMY_PIECE_TAKEN = "VOICE_ENEMY_PIECE_TAKEN";
local VOICE_FRIENDLY_PIECE_KINGED = "VOICE_FRIENDLY_PIECE_KINGED";
local VOICE_ENEMY_PIECE_KINGED = "VOICE_ENEMY_PIECE_KINGED";
local VOICE_FRIENDLY_KING_TAKEN = "VOICE_FRIENDLY_KING_TAKEN";
local VOICE_ENEMY_KING_TAKEN = "VOICE_ENEMY_KING_TAKEN";
local VOICE_WE_WON = "VOICE_WE_WON";
local VOICE_THEY_WON = "VOICE_THEY_WON";
local VOICE_GAME_STARTED = "VOICE_GAME_STARTED";
local VOICE_OUT_OF_RANGE = "VOICE_OUT_OF_RANGE";

local pieces = {};--holds the data for each checker
checkersVoices = {};--holds the sound files for our team
hostDeadCount, guestDeadCount = 0,0;
local TEAM_HOST = 0;--for checker pieces, is alliance
local TEAM_GUEST = 1;
checkersMode = MODE_WAITING_FOR_REQUESTS;

checkersPopFrame = CreateFrame('Frame','checkersPopFrame',UIParent);
local firstCheckerRun = true;--because frames must be used twice

local bgDragFrame = CreateFrame("FRAME",'bgDragFrame',UIParent);
local backgroundFrame = CreateFrame('Frame','backgroundFrame'
										,bgDragFrame);
backgroundFrame:SetPoint("TOP",bgDragFrame,"BOTTOM",0,0);
bgDragFrame:SetClampedToScreen(true);
backgroundFrame:SetClampedToScreen(true);
local option_sound = CreateFrame("CheckButton",
		"option_sound",bgDragFrame,"OptionsCheckButtonTemplate");
bgDragFrame:SetMovable(true);
bgDragFrame:EnableMouse(true);
bgDragFrame:RegisterForDrag("LeftButton");
bgDragFrame:SetScript("OnDragStart", bgDragFrame.StartMoving)
bgDragFrame:SetScript("OnDragStop",function(self)
 self:StopMovingOrSizing();

local dragLeft, dragBottom = self:GetLeft(), self:GetBottom();
if (dragBottom < heightB)
then
bgDragFrame:ClearAllPoints();
bgDragFrame:SetPoint("BOTTOMLEFT",dragLeft,heightB)
--saved variable handling
CheckersOptions["LocationX"] = dragLeft;
CheckersOptions["LocationY"] = heightB;
else
--saved variable handling
CheckersOptions["LocationX"] = dragLeft;
CheckersOptions["LocationY"] = dragBottom;
end


 
end)

local tex = backgroundFrame:CreateTexture();
local t2 = bgDragFrame:CreateTexture();
tex:SetAllPoints();
t2:SetAllPoints();
tex:SetAlpha(0.75);
t2:SetAlpha(1.00);
tex:SetTexture('Interface/AddOns/Checkers/images/checkers_background.tga');
t2:SetColorTexture(0.1686274509803922,0.0588235294117647,0.003921568627451);
checkersTurnText = bgDragFrame:CreateFontString("checkersTurnText","HIGH","GameFontNormal");
checkersStatusText = backgroundFrame:CreateFontString("checkersStatusText","HIGH","GameFontNormal");
 checkersStatusText:SetTextColor(1,0.643,0.169,1);
 checkersTurnText:SetTextColor(1,0.643,0.169,1);
 checkersStatusText:SetShadowColor(0,0,0,1);
 checkersTurnText:SetShadowColor(0,0,0,1);
 checkersStatusText:SetShadowOffset(2,-1);
 checkersTurnText:SetShadowOffset(2,-1);
 checkersStatusText:SetPoint("CENTER");
checkersTurnText:SetPoint("BOTTOM");
checkersStatusText:SetText("SAMPLE TEXT");
checkersTurnText:SetText("SAMPLE TEXT XD");
checkersStatusText:Show();
checkersTurnText:Show();
checkersStatusTextTimer = 0;
checkersStatusTextDuration = 5.0;



Checkers_eventFrame = CreateFrame("Frame");
Checkers_eventFrame:SetScript("OnUpdate", function(self, elapsed) Checkers_OnUpdate(self, elapsed) end)
Checkers_eventFrame:SetScript("OnEvent",function(self,event,...) self[event](self,event,...);end)
Checkers_eventFrame:RegisterEvent("VARIABLES_LOADED");

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
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function GetChessOrCheckersString()
if (isPlayingChess) then return "CHESS" else return "CHECKERS" end
end--end function GetChessOrCheckersString

local function pieceIsMyFaction(i)
return (
	(isHostingTheCheckersGame == true
	and pieces[i].team == TEAM_HOST
	) or
	(isHostingTheCheckersGame == false
	and pieces[i].team == TEAM_GUEST
	)
	);
end--end pieceIsMyFaction


local function reply(text)
SendChatMessage(text,"WHISPER",nil,checkersOpponentName);
end--end local function reply

local function setSecondaryStatusText(text)
checkersTurnText:SetText(text);
end--end function setSecondaryStatusText
local function setStatusText(text,duration,voice, noVoice)
if (noVoice and noVoice == 555) then return end;--was just checking if valid take
--handle sound effects for messages
if (voice ~= -1 and CheckersOptions["Sound"] == true) then
choice = math.random(getn(checkersVoices[voice]));
PlaySoundFile(checkersVoices[voice][choice]);
end

if (not (duration)) then duration = 5.0 end
checkersStatusTextTimer = 0;
checkersStatusTextDuration = duration;
checkersStatusText:SetText(text);
checkersStatusText:SetFont("Fonts\\FRIZQT__.TTF",
		widthB/13, "OUTLINE, MONOCHROME");
checkersStatusText:Show();
checkersStatusText:SetTextColor(1,0.643,0.169,1);
end--end function setStatusText(text[,duration])

local function setCheckersMode(mode)
checkersMode = mode;
if (mode == MODE_PLAYING)--game is starting.
then
if (isHostingTheCheckersGame == true)
then
setSecondaryStatusText("Welcome! You are alliance.");
else
setSecondaryStatusText("Welcome! You are horde.");
end--end else

end--end if


end--end local function setCheckersMode

local function leaveTheGame(reason)
if (reason == nil or not(reason) or 
	(reason ~= "Horde Wins!" and reason ~= "Alliance Wins!"
	and reason ~= "Other player left the game")) then
reason = "User clicked the exit button";
end
if (checkersMode ~= MODE_PLAYING) then return end;-- so no interference
backgroundFrame:Hide();
bgDragFrame:Hide();
reply(CHECKERS_LEAVING_MESSAGE);
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] " .. reason);
--delete all of the pieces?
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end--end local function leaveTheGame


function checkForCheckersGameOver()

if (hostDeadCount >= 12) then
end
if (guestDeadCount >= 12) then
end

end-- end function checkForCheckersGameOver

local function killPiece(index)
pieces[index].alive = false;
if (pieces[index].team == TEAM_HOST) then
if (isHostingTheCheckersGame == true)
then
if (pieces[index].king == true) then
setStatusText("One of your kings died!",8,VOICE_FRIENDLY_KING_TAKEN);
else
setStatusText("One of your men died!",8,VOICE_FRIENDLY_PIECE_TAKEN);
end--end king switch
else--is an enemy piece that died
if (pieces[index].king == true) then
setStatusText("You killed an enemy king!",8,VOICE_ENEMY_KING_TAKEN);
else
setStatusText("You killed an enemy!",8,VOICE_ENEMY_PIECE_TAKEN);
end--end king switch
end
hostDeadCount = hostDeadCount + 1;
elseif (pieces[index].team == TEAM_GUEST) then
if (isHostingTheCheckersGame == false)
then
setStatusText("One of your men died!",8,VOICE_FRIENDLY_PIECE_TAKEN);
else
setStatusText("You killed an enemy!",8,VOICE_ENEMY_PIECE_TAKEN);
end
guestDeadCount = guestDeadCount + 1;
end--end team host
pieces[index].checkerFrame:Hide();
checkForCheckersGameOver();
end--end function killPiece




--do animation letting them know it is their turn
local function setCheckersTurn(boolean)
if (boolean == true) then
setSecondaryStatusText("Your turn!");
setStatusText("Your Turn!",8,-1);
else
setSecondaryStatusText("Their turn.");
setStatusText("Their Turn!",8,-1);
end
isMyCheckersTurn = boolean;
end

function slashChess(msg, editBox)
slashCheckers(msg,editBox,true);
end--end function slashChess
function slashCheckers(msg, editBox, chessBool)



if (checkersMode == MODE_WAITING_FOR_ACCEPT)
then
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] Still waiting for " .. checkersOpponentName .. "'s response");
end

if (checkersMode ~= MODE_WAITING_FOR_REQUESTS)
then
return;--cant send requests in any other mode.
end

if (chessBool) then
tex:SetTexture('Interface/AddOns/Checkers/images/chess_background.tga');
isPlayingChess = true;
iAmAskingForChessNotCheckers = true;
else
tex:SetTexture('Interface/AddOns/Checkers/images/checkers_background.tga');
iAmAskingForChessNotCheckers = false;
isPlayingChess = false;
end--end if


local command, rest = msg:match("^(%S*)%s*(.-)$");
local targetName = "";
if (command == "") then
targetName = GetUnitName("target",true);
else

checkersOpponentName = command;
targetName = command;

end--end manual
if targetName and checkersMode == MODE_WAITING_FOR_REQUESTS and targetName ~= GetUnitName("player",true)
 then 
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] Sending game request to " .. targetName .. " . . .");
doTheyAlsoHaveTheAddon = 0;--begin timer
isHostingTheCheckersGame = true;
isMyCheckersTurn = true;
checkersOpponentName = targetName;
if (iAmAskingForChessNotCheckers) then
reply(CHESS_REQUEST_MESSAGE);
else
reply(CHECKERS_REQUEST_MESSAGE);
end--endif
 end--end valid request
if targetName == nil or targetName == GetUnitName("player",true)
 then
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] Target another player, then type |cffffffff/Checkers|cff8888ff, Or type |cffffffff/Checkers playername|cff8888ff.");
 end--end targeted self

end--end local function slashCheckers




local function putConfirmationBox()
if (isPlayingChess) then
tex:SetTexture('Interface/AddOns/Checkers/images/chess_background.tga');
else
tex:SetTexture('Interface/AddOns/Checkers/images/checkers_background.tga');
end
checkersPopFrame:SetPoint('CENTER',0,125)
local tex = checkersPopFrame:CreateTexture();
tex:SetAllPoints();
tex:SetTexture('Interface/AddOns/Checkers/images/startupScreen.tga');
 titleText = checkersPopFrame:CreateFontString("titleText",checkersPopFrame,"GameFontNormal");
 titleText:SetTextColor(1,0.643,0.169,1);
 titleText:SetShadowColor(0,0,0,1);
 titleText:SetShadowOffset(2,-1);
 titleText:SetPoint("TOP",tex,"TOP",0,-5);
titleText:SetText("Play " .. GetChessOrCheckersString() .." with " .. checkersOpponentName .. "?");
titleText:Show();

checkersPopFrame:SetFrameStrata('HIGH');
checkersPopFrame:SetSize(400,200);
checkersPopFrame:Show();
end-- end local function putConfirmationBox





local function handleDoTheyAlsoHaveTheAddon(elapsed)
if (doTheyAlsoHaveTheAddon == -555) then return end;
doTheyAlsoHaveTheAddon = doTheyAlsoHaveTheAddon + elapsed;
if (doTheyAlsoHaveTheAddon > 8.88) then
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] |cffff6666" .. checkersOpponentName .. " does not have the Checkers addon. |cffddddddTell them to download it from |cffffff00www.curse.com/addons/wow/Checkers |cff8888ffso they can play with you!")
doTheyAlsoHaveTheAddon = -555;
end--end they dont :-(

end--end local function doTheyAlsoHaveTheAddon

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



local function handleStatusTextUpdate(elapsed)
if (checkersStatusTextTimer > checkersStatusTextDuration) then
return;
end
checkersStatusTextTimer = checkersStatusTextTimer + elapsed;

if (checkersStatusTextTimer > checkersStatusTextDuration - 3.0) then
--do text fade
checkersStatusText:SetTextColor(1,0.643,0.169
	, (checkersStatusTextDuration - checkersStatusTextTimer)/3.0);
end

if (checkersStatusTextTimer > checkersStatusTextDuration) then
checkersStatusText:Hide();
end



end--end function handleStatusTextUpdate

function Checkers_OnUpdate(self, elapsed)
handleDoTheyAlsoHaveTheAddon(elapsed);
handleStatusTextUpdate(elapsed);

end--end onupdate


local function kingPiece(i, server)
if (pieceIsMyFaction(i)) then
setStatusText("You were kinged!",8,VOICE_FRIENDLY_PIECE_KINGED);
else
setStatusText("An enemy was kinged!",8,VOICE_ENEMY_PIECE_KINGED);
end
if (server and server == true) then
reply(">CHECKERS king " .. i);
else

end
pieces[i].king = true;
pieces[i].tx:SetAllPoints();
pieces[i].tx:SetAlpha(1);
if (pieces[i].team == TEAM_HOST) then
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/ak.tga');
else
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/hk.tga');
end--end team switch

end--end function kingPiece


function CheckersIncoming(ChatFrameSelf, event, message, author, ...)
local sarray = checkersSplitString(message);
--near end of function. dont put stuff below this.
if (not(sarray[1] == ">CHECKERS" or sarray[1] == ">CHESS")) then
return false;
end
if (sarray[2] == "king") then
kingPiece(tonumber(sarray[3]));
end
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
pieces[moveIndex].checkerFrame:ClearAllPoints();
pieces[moveIndex].checkerFrame:SetPoint("BOTTOMLEFT",
convertColumnToX(pieces[moveIndex].column),convertRowToY(pieces[moveIndex].row));
if (removedIndex ~= -1) then
--kill the piece
killPiece(removedIndex);
end--end something was removed
--handle turn
if (turnEnded == 1) then
setCheckersTurn(true);
end
end--end update
if (message == CHECKERS_ACCEPT_REQUEST_MESSAGE) then
startCheckers();

end--end message = CHECKERS_ACCEPT_REQUEST_MESSAGE
if (message == CHECKERS_REQUEST_MESSAGE and checkersMode == MODE_WAITING_FOR_REQUESTS) then
checkersOpponentName = author;
isPlayingChess = false;
isHostingTheCheckersGame = false;
reply(CHECKERS_REQUEST_ACKNOWLEDGED);
setCheckersMode(MODE_ANSWERING_REQUEST);
putConfirmationBox();
end--end checkersrequest message

if (message == CHESS_REQUEST_MESSAGE and checkersMode == MODE_WAITING_FOR_REQUESTS) then
checkersOpponentName = author;
isPlayingChess = true;
isHostingTheCheckersGame = false;
reply(CHECKERS_REQUEST_ACKNOWLEDGED);
setCheckersMode(MODE_ANSWERING_REQUEST);
putConfirmationBox();
end--end checkersrequest message

if (message == CHECKERS_LEAVING_MESSAGE) then
leaveTheGame("Other player left the game");
end--end leaving
if (message == CHECKERS_DECLINE_REQUEST_MESSAGE) then
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] " .. author .. " declined your invitation to play. What a jerk!");
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end
if (message == CHECKERS_REQUEST_ACKNOWLEDGED and doTheyAlsoHaveTheAddon ~= -555) then
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] " .. author .. " has the addon! Waiting for their response now...");
checkersOpponentName = author;
setCheckersMode(MODE_WAITING_FOR_ACCEPT);
doTheyAlsoHaveTheAddon = -555;
end



return true;--displaymessageornotthing?
end--end local function CheckersIncoming
function CheckersOutgoing(ChatFrameSelf, event, message, author, ...)
local sarray = checkersSplitString(message);
if (sarray[1] == ">CHECKERS" or sarray[1] == ">CHESS") then
return true;
end
return false;

end--end local function CheckersOutgoing

local function isOutOfBounds(r,c)
return (r < 9 and r > 0 and c < 9 and c > 0);
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

end--end function isSpaceOCcupied

--[[isValid, takenIndex = isValidChessMove(i,pieces[i].row,pieces[i].column,
		landedRow,landedColumn, pieces[i].team,pieces[i].name);
]]
function isValidChessMove(thisPiece,r1,c1,r2,c2,team,name,noVoice)


--handle the attempted movement of pieces that are just display.
if (thisPiece ~= -1 and pieces[thisPiece].alive == false) then return false; end

--make sure it's player's turn.
if (isMyCheckersTurn == false) then
setStatusText("It is their turn.",8,VOICE_WRONG_TURN,noVoice);
return false
end;
--if he doesnt move >:-(
if (r1 == r2 and c1 == c2) then 
setStatusText("You have to move something.",8,VOICE_INVALID_MOVE,noVoice);
return false
end

--check board boundaries
if (r2 <= 0 or r2 >= 9 or c2 <= 0 or c2 >= 9) then
setStatusText("Out of bounds",8,VOICE_OUT_OF_RANGE,noVoice);
return false;
end--end out of board bounds

--now check if this piece is capable of moving in that direction (knight etc)
topbot = "TOP";
if (isHostingTheCheckersGame) then topbot = "BOTTOM" end




attemptedLandingIndex = isSpaceOccupied(r2,c2);
	
setStatusText("can't go there mate",8,VOICE_WRONG_TURN,noVoice)--to be overwritten
if (name == "pawn") then
if (topbot == "BOTTOM") then
if (c2-c1==0 and r2-r1==1 and isSpaceOccupied(r2,c2) == -1 
		or
	r1 == 2 and c2-c1==0 and r2-r1==2 and isSpaceOccupied(r1+1,c2) == -1 and isSpaceOccupied(r1+2,c2) == -1
	) then return true end 
	if (abs(c2-c1)==1 and r2-r1==1 and isChessEnemy(r2,c2)) then return true, isSpaceOccupied(r2,c2) end
else--elsetop
if (c2-c1==0 and r2-r1==-1 and isSpaceOccupied(r2,c2) == -1 
		or
	r1 == 7 and c2-c1==0 and r2-r1==-2 and isSpaceOccupied(r1-1,c2) == -1 and isSpaceOccupied(r1-2,c2) == -1
	) then return true end
	if (abs(c2-c1)==1 and r2-r1==-1 and isChessEnemy(r2,c2)) then return true, isSpaceOccupied(r2,c2) end
end--end elsetop
end--end pawn

if (name == "rook") then
if (c2-c1==0 and r2~=r1) then
for y=r1+boolToPolarity(r2>r1),r2,boolToPolarity(r2>r1) do
if (isSpaceOccupied(y,c2) ~= -1) then
	if (y == r2 and isChessEnemy(r2,c2)) then return true, attemptedLandingIndex end--take the peice
	return false
end--end if
end--end for
return true--fallthrough
end--end if rowmovement
if (r2-r1==0 and c2~=c1) then
for x=c1+boolToPolarity(c2>c1),c2,boolToPolarity(c2>c1) do
	if (isSpaceOccupied(r2,x) ~= -1) then
	if (x == c2 and isChessEnemy(r2,c2)) then return true, attemptedLandingIndex end
	return false
	end--end if
end--end for
return true, attemptedLandingIndex--fallthrough
end--end if colmovement
end--end rook
if (name == "bishop") then
if (abs(r2-r1)~=abs(c2-c1)) then return false end;--not a diagonal movement!
for x=c1+boolToPolarity(c2>c1),c2,boolToPolarity(c2>c1) do

if (isSpaceOccupied(r1+boolToPolarity(r2>r1)*abs(x-c1),x) ~= -1) then

	if (x == c2 and isChessEnemy(r2,c2)) then return true, attemptedLandingIndex 
	end 
	return false
end--end if
end--end for
return true, attemptedLandingIndex
end--end bishop

if (name == "knight") then
return (isChessEnemy(r2,c2) or isSpaceOccupied(r2,c2)==-1) and ((abs(r2-r1)==1 and abs(c2-c1) == 2 
				or
					abs(r2-r1)==2 and abs(c2-c1) == 1)), attemptedLandingIndex;
end--end name==knight

if (name == "king") then
return (isChessEnemy(r2,c2) or isSpaceOccupied(r2,c2)==-1) and (abs(r2-r1) <= 1 and abs(c2-c1) <= 1), attemptedLandingIndex;
end--end name==king

if (name == "queen") then
--copypsated from rook.
if (c2-c1==0 and r2~=r1) then
for y=r1+boolToPolarity(r2>r1),r2,boolToPolarity(r2>r1) do
if (isSpaceOccupied(y,c2) ~= -1) then
	if (y == r2 and isChessEnemy(r2,c2)) then return true, attemptedLandingIndex end--take the peice
	return false
end--end if
end--end for
return true--fallthrough
end--end if rowmovement
if (r2-r1==0 and c2~=c1) then
for x=c1+boolToPolarity(c2>c1),c2,boolToPolarity(c2>c1) do
	if (isSpaceOccupied(r2,x) ~= -1) then
	if (x == c2 and isChessEnemy(r2,c2)) then return true, attemptedLandingIndex end
	return false
	end--end if
end--end for

return true, attemptedLandingIndex--fallthrough
end--end if colmovement

--copypasting from bishops
if (abs(r2-r1)==abs(c2-c1)) then
for x=c1+boolToPolarity(c2>c1),c2,boolToPolarity(c2>c1) do
print("yRow= " .. (r1+boolToPolarity(r2>r1)*abs(x-c1)).. " xCol=" .. x)
if (isSpaceOccupied(r1+boolToPolarity(r2>r1)*abs(x-c1),x) ~= -1) then

	if (x == c2 and isChessEnemy(r2,c2)) then return true, attemptedLandingIndex 
	end 
	
	return false
end--end if
end--end for
return true, attemptedLandingIndex
end--end if diagonalmovement

end--end name==queen



setStatusText("huehue",8,VOICE_WRONG_TURN,noVoice);
return false;

end--end function isValidChessMove
function isChessEnemy(r,c)
index = isSpaceOccupied(r,c) 

if (index == -1) then return false end
return (pieces[index].team == TEAM_GUEST and isHostingTheCheckersGame)
		or
	   (pieces[index].team == TEAM_HOST and isHostingTheCheckersGame == false)
end--end function isChessEnemy
function boolToPolarity(bool)
if (bool) then return 1 else return -1 end
end--end function boolToPolarity
--[[
if noVoice == 555 then noVoice.
function isValidCheckersMove - returns 2 values
returns (booleanValid [, takenPieceIndex])
--]]
local function isValidCheckersMove(thisPiece, r1, c1, r2, c2, team, king, noVoice)
--handle the attempted movement of pieces that are just display.
if (thisPiece ~= -1 and pieces[thisPiece].alive == false) then return false; end

--make sure it's player's turn.
if (isMyCheckersTurn == false) then
setStatusText("It is their turn.",8,VOICE_WRONG_TURN,noVoice);
return false
end;
--check board boundaries
if (r2 <= 0 or r2 >= 9 or c2 <= 0 or c2 >= 9) then
setStatusText("Out of bounds",8,VOICE_OUT_OF_RANGE,noVoice);
return false;
end--end out of board bounds
--check if r2,c2 is occupied
if (isSpaceOccupied(r2,c2) ~= -1) then
setStatusText("Space is taken",8,VOICE_INVALID_MOVE,noVoice);
return false;
end
--check legal diagonal single move for non-king
if (isAPieceTakeTurn == false) then
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
end--end isAPieceTakeTurn==false
--check legal diagonal single move for king
if (king == true and isAPieceTakeTurn == false)
then
if (r2 == r1 + 1 and (c2 == c1 + 1 or c2 == c1 - 1))
	or
(r2 == r1 - 1 and (c2 == c1 + 1 or c2 == c1 - 1)) then
return true;
end--end if
end--end king == true and isAPieceTakeTurn == false

local iso = isSpaceOccupied((r2+r1)/2,(c2+c1)/2);
--check legal piece-take-move for non-king
if (team == TEAM_HOST) then
if (r2 == r1 + 2 and (c2 == c1 + 2 or c2 == c1 - 2)
	and iso ~= -1 and pieces[iso].team == TEAM_GUEST)
then
return true, iso;
end--end piece take by host
else--else team == TEAM_GUEST, non-king
if (r2 == r1 - 2 and (c2 == c1 + 2 or c2 == c1 - 2)
	and iso ~= -1 and pieces[iso].team == TEAM_HOST)
then
return true, iso;
end--end if
end--end not-host-else

--check legal piece-take-move for king
if (king == true and 
(r2 == r1 + 2 or r2 == r1 - 2) and (c2 == c1 + 2 or c2 == c1 - 2)
	and iso ~= -1 
	and	((team == TEAM_GUEST and pieces[iso].team == TEAM_HOST)
	or (team == TEAM_HOST and pieces[iso].team == TEAM_GUEST)))
then
return true, iso;
end--end piece take by host

setStatusText("Nope",8,VOICE_INVALID_MOVE,noVoice);
return false;--default case
end--end isValidCheckersMove

function thereAreValidTakesForPiece(i)

--if king then can take either way
--otherwise 
--do each corner.
r = pieces[i].row;
c = pieces[i].column;
king = pieces[i].king;
team = pieces[i].team;
--local function isValidCheckersMove(thisPiece, r1, c1, r2, c2, team, king)
return (isValidCheckersMove(i,r,c,r-2,c-2,team,king,555)
	or
	isValidCheckersMove(i,r,c,r-2,c+2,team,king,555)
	or
	isValidCheckersMove(i,r,c,r+2,c+2,team,king,555)
	or
	isValidCheckersMove(i,r,c,r+2,c-2,team,king,555)
	);
end--end function thereAreValidTakesForPiece

CHESS_PIECE_NAMES = {"rook","knight","bishop","king",
					"queen","bishop","knight","rook",
					"pawn","pawn","pawn","pawn",
					"pawn","pawn","pawn","pawn",
					
					"pawn","pawn","pawn","pawn",
					"pawn","pawn","pawn","pawn",
					"rook","knight","bishop","king",
					"queen","bishop","knight","rook"
					};
CHESS_ROWS = {1,1,1,1,
			  1,1,1,1,
			  2,2,2,2,
			  2,2,2,2,
			  
			  7,7,7,7,
			  7,7,7,7,
			  8,8,8,8,
			  8,8,8,8};
CHESS_COLUMNS = {1,2,3,4,
				 5,6,7,8,
				 1,2,3,4,
				 5,6,7,8,
				 
				 1,2,3,4,
				 5,6,7,8,
				 1,2,3,4,
				 5,6,7,8
				 };
CHESS_TEAMS = {TEAM_HOST,TEAM_HOST,TEAM_HOST,TEAM_HOST,
			   TEAM_HOST,TEAM_HOST,TEAM_HOST,TEAM_HOST,
			   TEAM_HOST,TEAM_HOST,TEAM_HOST,TEAM_HOST,
			   TEAM_HOST,TEAM_HOST,TEAM_HOST,TEAM_HOST,
			   TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,
			   TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,
			   TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,
			   TEAM_GUEST,TEAM_GUEST,TEAM_GUEST,TEAM_GUEST};

local function createPieces()

for i = 1, 8*2*2 do
if pieces and pieces[i] and pieces[i].checkerFrame then
pieces[i].checkerFrame:Hide();
end
end--endfor
if (isPlayingChess) then
numPieces = 8*2*2; 
else
numPieces = 24;
end

if (isPlayingChess) then
for i = 1, numPieces do
pieces[i] = {
row = CHESS_ROWS[i];--row 1 is the bottom row.
column = CHESS_COLUMNS[i];
team = CHESS_TEAMS[i];
name = CHESS_PIECE_NAMES[i];
king = false;--nil
alive = true;
checkerFrame;
tx = nil;
};

local kids = {backgroundFrame:GetChildren()};
pieces[i].checkerFrame = CreateFrame("FRAME", "checkerFrame" .. i,
								backgroundFrame);
--only allow the player to move his own pieces.
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
isValid, takenIndex = isValidChessMove(i,pieces[i].row,pieces[i].column,
		landedRow,landedColumn, pieces[i].team,pieces[i].name);
		
if (takenIndex == nil) then takenIndex = -1; end
if (isValid == true)
		then
		--this will be done on the other players machine too via socket message
		pieces[i].row = landedRow;
		pieces[i].column = landedColumn;
		if ((pieces[i].row == 1 or pieces[i].row == 8) and pieces[i].name=="pawn")
		then
		queenPiece(i,true);
		end
		--check if a piece was taken
		if (takenIndex and takenIndex ~= -1)
		then
		killPiece(takenIndex);
		end--end taken
		local endMyTurn = 1;
		
		--done taking pieces. end the turn.
		
		--TODO make them move if king is in check idk
		
		
		setStatusText("Turn ended",4,-1);
		setCheckersTurn(false);
		
		--broadcast the move via turnUpdateMessage
		reply(">CHECKERS update " .. i .. " " .. landedRow .. " " ..
					landedColumn .. " " .. takenIndex .. " " .. endMyTurn);
		else
		--was not a valid move -- put it back!
		end
		pieces[i].checkerFrame:ClearAllPoints();
		pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",convertColumnToX(pieces[i].column),
				convertRowToY(pieces[i].row));
end); 
else
--cleanup from last run so you cant move enemies pieces
pieces[i].checkerFrame:SetMovable(false);
pieces[i].checkerFrame:EnableMouse(false);
end--end isOneOfMyPiecesSoLetMeMoveIt

pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",(CHESS_COLUMNS[i]-1)*widthB/8,(CHESS_ROWS[i]-1)*heightB/8);
pieces[i].checkerFrame:SetSize(widthB/8,heightB/8);
pieces[i].tx = pieces[i].checkerFrame:CreateTexture();
pieces[i].tx:SetAllPoints();
pieces[i].tx:SetAlpha(1);

if (pieces[i].team == TEAM_HOST) then
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/' .. CHESS_PIECE_NAMES[i] .. '_white.tga');
else
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/' .. CHESS_PIECE_NAMES[i] .. '_black.tga');
end
pieces[i].checkerFrame:Show();



end--end for chesspieces

end--end isPlayingChess

if (not(isPlayingChess)) then
local r,c = 1,2;
local t = TEAM_HOST;--placeholderfornowwhat
for i = 1, numPieces do 
pieces[i] = {
row = r;--row 1 is the bottom row.
column = c;
team = t;
king = false;
alive = true;
checkerFrame;
tx = nil;
};

local kids = {backgroundFrame:GetChildren()};

pieces[i].checkerFrame = CreateFrame("FRAME", "checkerFrame" .. i,
								backgroundFrame);



--only allow the player to move his own pieces.
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
isValid, takenIndex = isValidCheckersMove(i,pieces[i].row,pieces[i].column,
		landedRow,landedColumn, pieces[i].team,pieces[i].king);
if (isValid == false and isAPieceTakeTurn == true) then
setStatusText("You must take a piece.",8,-1);
end--error message from when you must take a piece
if (takenIndex == nil) then takenIndex = -1; end
if (isValid == true)
		then
		--this will be done on the other players machine too via socket message
		pieces[i].row = landedRow;
		pieces[i].column = landedColumn;
		if ((pieces[i].row == 1 or pieces[i].row == 8) and pieces[i].king == false)
		then
		kingPiece(i,true);
		end
		--check if a piece was taken
		if (takenIndex and takenIndex ~= -1)
		then
		killPiece(takenIndex);
		end--end taken
		local endMyTurn = 1;
		if (takenIndex and takenIndex ~= -1 and
				thereAreValidTakesForPiece(i) == true)
		then
		--dont end their turn if they can still take another piece.
		endMyTurn = 0;
		--next turn will require them to take a piece. only valid move.
		isAPieceTakeTurn = true;
		setStatusText("Still your turn -- take next piece",8,-1);
		else
		--done taking pieces. end the turn.
		endMyturn = 1;
		isAPieceTakeTurn = false;
		setStatusText("Turn ended",4,-1);
		end
		if (endMyTurn == 1) then
		setCheckersTurn(false);
		end
		--broadcast the move via turnUpdateMessage
		reply(">CHECKERS update " .. i .. " " .. landedRow .. " " ..
					landedColumn .. " " .. takenIndex .. " " .. endMyTurn);
		else
		--was not a valid move -- put it back!
		end
		pieces[i].checkerFrame:ClearAllPoints();
		pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",convertColumnToX(pieces[i].column),
				convertRowToY(pieces[i].row));
end); 
else
--cleanup from last run so you cant move enemies pieces
pieces[i].checkerFrame:SetMovable(false);
pieces[i].checkerFrame:EnableMouse(false);
end--end isOneOfMyPiecesSoLetMeMoveIt
pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",(c-1)*widthB/8,(r-1)*heightB/8);
pieces[i].checkerFrame:SetSize(widthB/8,heightB/8);
pieces[i].tx = pieces[i].checkerFrame:CreateTexture();

if (pieces[i].team == TEAM_HOST) then
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/alliance_checker.tga');
else
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/horde_checker.tga');
end
pieces[i].tx:SetAllPoints();
pieces[i].tx:SetAlpha(1);
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
end--end if playing checkers


firstCheckerRun = false;--the frames have all been instantiated.
end--end function createPieces

function populateCheckersSounds()
local placeHolder = "";
--chooses array assignment based on faction
checkersVoices = isHostingTheCheckersGame and {
VOICE_WRONG_TURN = {
--i cant do that yet
"Sound\\Character\\NightElf\\NightElfMaleErrorMessages\\NightElfMale_err_abilitycooldown02.ogg"
--check
},
VOICE_INVALID_MOVE = {
--i cant put that there
"Sound\\Character\\NightElf\\NightElfMaleErrorMessages\\NightElfMale_err_ammoonly02.ogg",
"Sound\\Character\\Draenei\\DraeneiMale_Err_AmmoOnly01.ogg",
"Sound\\Character\\Dwarf\\DwarfMaleErrorMessages\\DwarfMale_err_ammoonly02.ogg",
"Sound\\Character\\Gnome\\GnomeMaleErrorMessages\\GnomeMale_err_ammoonly02.ogg",
"Sound\\Character\\Human\\MaleErrorMessages\\HumanMale_err_ammoonly02.ogg"
--check
},
VOICE_FRIENDLY_PIECE_TAKEN = {
--roars
"Sound/character/Draenei/DraeneiMaleRoar01.ogg",
"Sound/character/Dwarf/DwarfVocalMale/VO_PCDwarfMaleRoar01.ogg",
"Sound/character/Gnome/GnomeVocalMale/VO_PCGnomeMaleRoar01.ogg",
"Sound/character/Human/HumanVocalMale/VO_PCHumanMaleRoar01.ogg",
"Sound/character/NightElf/NightElfVocalMale/VO_PCNightElfMaleRoar01.ogg",
"Sound/character/PCWorgenMale/VO_PCWorgenMale_Roar01.ogg"
--check
},
VOICE_ENEMY_PIECE_TAKEN = {
"Sound/character/BloodElf/BloodElfMaleRoar01.ogg",
"Sound/character/Orc/OrcVocalMale/VO_PCOrcMaleRoar01.ogg",
"Sound/character/PCGilneanMale/VO_PCGilneanMale_Roar01.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar01.ogg"
--check
},
VOICE_FRIENDLY_PIECE_KINGED = {
	--alliance king noises
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_01-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_02-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_03-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_04-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_05-01.OGG"
--check
},
VOICE_ENEMY_PIECE_KINGED = {
	--horde king noises
"Sound/creature/GARROSH/CR_Garrosh_HArrival02.ogg"
--check, needs another better one
},
VOICE_FRIENDLY_KING_TAKEN = {
--"worthless scrub" LOL
"Sound/creature/VarianWrynn/CR_Varian_KillH03.ogg"
--check
},
VOICE_ENEMY_KING_TAKEN = {
"Sound/creature/GARROSH/CR_Garrosh_Death02.ogg"
--check
},
VOICE_WE_WON = {
"Sound/Doodad/Firecrackers_ThrownExplode.ogg",
"Sound/Doodad/FirecrackerStringExplode.ogg"
--check, weak tho
},
VOICE_THEY_WON = {
placeHolder
},
VOICE_GAME_STARTED_ALLIANCE = {
placeHolder
},
VOICE_GAME_STARTED_HORDE = {
placeHolder
},
VOICE_OUT_OF_RANGE = {
"Sound/character/Human/MaleErrorMessages/HumanMale_err_loottoofar02.ogg",
"Sound/character/Human/MaleErrorMessages/HumanMale_err_loottoofar03.ogg",
"Sound/character/Human/MaleErrorMessages/HumanMale_err_loottoofar04.ogg",
"Sound/character/NightElf/NightElfMaleErrorMessages/NightElfMale_err_loottoofar02.ogg",
"Sound/character/NightElf/NightElfMaleErrorMessages/NightElfMale_err_loottoofar03.ogg",
"Sound/character/NightElf/NightElfMaleErrorMessages/NightElfMale_err_loottoofar04.ogg"
--check
}
} or--end alliance voice table
{
VOICE_WRONG_TURN = {
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_abilitycooldown02.ogg",
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_abilitycooldown03.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_abilitycooldown02.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_abilitycooldown03.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_abilitycooldown02.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_abilitycooldown03.ogg"
--check
},
VOICE_INVALID_MOVE = {
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_ammoonly02.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_ammoonly02.ogg",
"Sound/character/Troll/TrollMaleErrorMessages/TrollMale_err_ammoonly02.ogg",
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_ammoonly02.ogg"
--check
},
VOICE_FRIENDLY_PIECE_TAKEN = {
"Sound/character/BloodElf/BloodElfMaleRoar01.ogg",
"Sound/character/Orc/OrcVocalMale/VO_PCOrcMaleRoar01.ogg",
"Sound/character/PCGilneanMale/VO_PCGilneanMale_Roar01.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar01.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar02.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar03.ogg"


},
VOICE_ENEMY_PIECE_TAKEN = {
"Sound/character/Draenei/DraeneiMaleRoar01.ogg",
"Sound/character/Dwarf/DwarfVocalMale/VO_PCDwarfMaleRoar01.ogg",
"Sound/character/Gnome/GnomeVocalMale/VO_PCGnomeMaleRoar01.ogg",
"Sound/character/Human/HumanVocalMale/VO_PCHumanMaleRoar01.ogg",
"Sound/character/NightElf/NightElfVocalMale/VO_PCNightElfMaleRoar01.ogg",
"Sound/character/PCWorgenMale/VO_PCWorgenMale_Roar01.ogg"
},
VOICE_FRIENDLY_KING_TAKEN = {
"Sound/creature/GARROSH/CR_Garrosh_Death02.ogg"

},
VOICE_ENEMY_KING_TAKEN = {
"Sound/creature/VarianWrynn/CR_Varian_KillH01.ogg",
"Sound/creature/VarianWrynn/CR_Varian_KillH02.ogg",
"Sound/creature/VarianWrynn/CR_Varian_KillH03.ogg",
"Sound/creature/VarianWrynn/CR_Varian_KillH04.ogg"
},
VOICE_FRIENDLY_PIECE_KINGED = {
	--horde king noises
"Sound/creature/GARROSH/CR_Garrosh_HArrival02.ogg"
},
VOICE_ENEMY_PIECE_KINGED = {
	--alliance king noises
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_01-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_02-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_03-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_04-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_05-01.OGG"
},
VOICE_WE_WON = {
"Sound/Doodad/Firecrackers_ThrownExplode.ogg",
"Sound/Doodad/FirecrackerStringExplode.ogg"
},
VOICE_THEY_WON = {
placeHolder
},
VOICE_GAME_STARTED_ALLIANCE = {
placeHolder
},
VOICE_GAME_STARTED_HORDE = {
placeHolder
},
VOICE_OUT_OF_RANGE = {
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_outofrange02.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_outofrange04.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_outofrange05.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_outofrange02.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_outofrange04.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_outofrange05.ogg",
"Sound/character/Troll/TrollMaleErrorMessages/TrollMale_err_outofrange02.ogg",
"Sound/character/Troll/TrollMaleErrorMessages/TrollMale_err_outofrange04.ogg",
"Sound/character/Troll/TrollMaleErrorMessages/TrollMale_err_outofrange05.ogg"
--check
}

};--end horde voice table


end--end function populateCheckersSounds

function startCheckers()
setCheckersMode(MODE_PLAYING);
createPieces();
populateCheckersSounds();
--draw the frames
checkersPopFrame:Hide();

backgroundFrame:SetFrameStrata('MEDIUM');
backgroundFrame:Show(); 
bgDragFrame:Show();
if (isPlayingChess) then
if (isHostingTheCheckersGame)
then
setStatusText("Welcome! You are White.",50,-1);
else
setStatusText("Welcome! You are Black.",50,-1)
end

else
if (isHostingTheCheckersGame)
then
setStatusText("Welcome! You are Alliance.",50,-1);
else
setStatusText("Welcome! You are Horde.",50,-1)
end
end--end is chess

end--end function startCheckers

local function acceptButtonPressed()
reply(CHECKERS_ACCEPT_REQUEST_MESSAGE);
setCheckersMode(MODE_PLAYING);
isMyCheckersTurn = false;
startCheckers();
end


local function declineButtonPressed()
checkersPopFrame:Hide();
reply(CHECKERS_DECLINE_REQUEST_MESSAGE);
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end


local function makeFramesGreatAgain()
--make them great again xD
--we are given a new widthB and heightB variable.
--need to update the field and everything to reflect these changes.
--background frames
--save new values here
CheckersOptions["Size"] = widthB;


backgroundFrame:SetPoint("TOP",0,-25);
backgroundFrame:SetSize(widthB,heightB);
bgDragFrame:SetSize(widthB,25);

--various buttons
option_sound:SetPoint("LEFT");


--checker piece locations
local kids = {backgroundFrame:GetChildren()};

for _,checker in ipairs(kids) do
local name = checker:GetName();
local index = tonumber(string.sub(name,strlen("checkerFrame")+1));
if (isPlayingChess) then
numPieces = 8*2*2;
else
numPieces = 24;
end

if (index and index >= 1 and index <= numPieces) then
pieces[index].checkerFrame:SetPoint("BOTTOMLEFT",
				convertColumnToX(pieces[index].column),
				convertRowToY(pieces[index].row));
pieces[index].checkerFrame:SetSize(widthB/8,heightB/8);
end--end if index is checkerd
end--end for iterator

end--end function makeFramesGreatAgain


local function makeFrameBigger()
if (widthB >= 530) then return end
widthB = widthB + 30;
heightB = widthB;
makeFramesGreatAgain();

end--end function makeFrameBigger

local function makeFrameSmaller()
if (widthB <= 200) then return end
widthB = widthB - 30;
heightB = widthB;
makeFramesGreatAgain();

end--end function makeFrameSmaller

function Checkers_initialize()--called from the XML
local acceptFrame = CreateFrame("Button", "acceptFrame", checkersPopFrame, "UIPanelButtonTemplate");
acceptFrame:SetText("Accept Game");
acceptFrame:SetPoint("CENTER",-108-22,-22);
acceptFrame:SetWidth(108);
acceptFrame:SetHeight(22);
acceptFrame:SetScript("OnClick", acceptButtonPressed);
acceptFrame:SetBackdropBorderColor(0,0,1);--include alpha?
acceptFrame:SetBackdropColor(0,0,1);
acceptFrame:Show();
local declineFrame = CreateFrame("Button", "declineFrame", checkersPopFrame, "UIPanelButtonTemplate");
declineFrame:SetText("Decline Game");
declineFrame:SetPoint("CENTER",108+22,-22);
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
local bigBonedFrame = CreateFrame("Button","bigBonedFrame",bgDragFrame,"UIPanelButtonTemplate");
bigBonedFrame:SetText("+");
bigBonedFrame:SetPoint("BOTTOMRIGHT",0,0);
bigBonedFrame:SetSize(24,24);
bigBonedFrame:SetScript("OnClick", makeFrameBigger);
bigBonedFrame:SetBackdropColor(0,0,1);
bigBonedFrame:SetFrameStrata("HIGH");
bigBonedFrame:Show();
local anorexicFrame = CreateFrame("Button","anorexicFrame",bigBonedFrame,"UIPanelButtonTemplate");
anorexicFrame:SetText("-");
anorexicFrame:SetPoint("RIGHT",bigBonedFrame,"LEFT",0,0);
anorexicFrame:SetSize(24,24);
anorexicFrame:SetScript("OnClick", makeFrameSmaller);
anorexicFrame:SetBackdropColor(0,0,1);
anorexicFrame:Show();


end--end Checkers_initialize



local function CreateOptions()
if ((not CheckersOptions) or CheckersOptions["Sound"] == nil
	or CheckersOptions["LocationY"] == nil) then
--constructor
print("instantiating CheckersOptions");
CheckersOptions = {["Sound"] = true, ["Size"] = widthB_DEFAULT,
					["LocationX"] = -1, ["LocationY"] = -1};
end--end constructor

--make the buttons!

_G[option_sound:GetName() .. "Text"]:SetText("sound");
option_sound:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText("Toggle checkers game sound effects and voices");
end);
--label the button
 soundText = backgroundFrame:CreateFontString("soundText",backgroundFrame,"GameFontNormal");
 soundText:SetTextColor(1,0.643,0.169,1);
 soundText:SetShadowColor(0,0,0,1);
 soundText:SetShadowOffset(2,-1);
 soundText:ClearAllPoints();
 soundText:SetPoint("LEFT",option_sound,"RIGHT",0,0);
soundText:SetText("Sound");
soundText:Show();

option_sound:SetPoint("BOTTOMLEFT");
option_sound.setFunc = function(value) 
CheckersOptions["Sound"] = (value == "1");
end--end anonymous function


--load options
option_sound:SetChecked(CheckersOptions["Sound"]);
widthB = CheckersOptions["Size"];
heightB = widthB;
backgroundFrame:SetSize(widthB,heightB);
bgDragFrame:SetSize(widthB,25);
--now frame location option saved variable
bgDragFrame:ClearAllPoints();
if (CheckersOptions["LocationX"] == -1)
then
bgDragFrame:SetPoint("TOP");
else--it is a valid location, so move it there.
bgDragFrame:SetPoint("BOTTOMLEFT",
					CheckersOptions["LocationX"],
					CheckersOptions["LocationY"]);
end
bgDragFrame:Hide();

end--end function CreateOptions
function Checkers_OnLoad()
print("|cff8888ff" .. "[" .. GetChessOrCheckersString() .. "] addon loaded! Type '/Checkers' while targeting a player to play against them. They must also have the addon: |cffffff00www.curse.com/addons/wow/checkers");
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",CheckersIncoming);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CheckersOutgoing);
end--end Checkers_OnLoad


function Checkers_eventFrame:VARIABLES_LOADED()
CreateOptions();
end--end function VARIABLES_LOADED


