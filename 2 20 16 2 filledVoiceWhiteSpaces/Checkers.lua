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
local otherPlayer = "Invalid Name";
local heightB = 600;
local widthB = heightB;--square board.
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
local hostDeadCount, guestDeadCount = 0,0;
local TEAM_HOST = 0;--for checker pieces, is alliance
local TEAM_GUEST = 1;
checkersMode = MODE_WAITING_FOR_REQUESTS;

local popframe = CreateFrame('Frame','popframe',UIParent);
local firstCheckerRun = true;--because frames must be used twice

local bgDragFrame = CreateFrame("FRAME",'bgDragFrame',UIParent);
local backgroundFrame = CreateFrame('Frame','backgroundFrame'
										,bgDragFrame);
bgDragFrame:SetMovable(true);
bgDragFrame:EnableMouse(true);
bgDragFrame:RegisterForDrag("LeftButton");
bgDragFrame:SetScript("OnDragStart", bgDragFrame.StartMoving)
bgDragFrame:SetScript("OnDragStop",function(self)
 self:StopMovingOrSizing();
end)

local tex = backgroundFrame:CreateTexture();
local t2 = bgDragFrame:CreateTexture();
tex:SetAllPoints();
t2:SetAllPoints();
tex:SetAlpha(0.75);
t2:SetAlpha(1.00);
tex:SetTexture('Interface/AddOns/Checkers/images/checkers_background.tga');
t2:SetTexture(0.1686274509803922,0.0588235294117647,0.003921568627451);
checkersStatusText = backgroundFrame:CreateFontString("checkersStatusText","HIGH","GameFontNormal");
 checkersStatusText:SetTextColor(1,0.643,0.169,1);
 checkersStatusText:SetShadowColor(0,0,0,1);
 checkersStatusText:SetShadowOffset(2,-1);
 checkersStatusText:SetPoint("TOPLEFT",tex,"TOPLEFT",
		widthB/2-widthB/8,widthB/2/8/2);
checkersStatusText:SetText("SAMPLE TEXT");
checkersStatusText:Show();
checkersStatusTextTimer = 0;
checkersStatusTextDuration = 5.0;



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
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

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



local function setStatusText(text,duration,voice)
--handle sound effects for messages
if (voice ~= nil) then
print(text .. ", " .. voice);
PlaySoundFile(checkersVoices[voice][1]);
end


if (not (duration)) then duration = 5.0 end
checkersStatusTextTimer = 0;
checkersStatusTextDuration = duration;
checkersStatusText:SetText(text);
checkersStatusText:SetFont("Fonts\\FRIZQT__.TTF",
		widthB/8, "OUTLINE, MONOCHROME");
checkersStatusText:Show();
checkersStatusText:SetTextColor(1,0.643,0.169,1);
end--end function setStatusText(text[,duration])

function checkForCheckersGameOver()
if (hostDeadCount >= 12) then
leaveTheGame("Horde Wins!");
end
if (guestDeadCount >= 12) then
leaveTheGame("Alliance Wins!");
end

end-- end function checkForCheckersGameOver

local function killPiece(index)
pieces[index].alive = false;
if (pieces[index].faction == TEAM_HOST) then
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
elseif (pieces[index].faction == TEAM_GUEST) then
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



local function reply(text)
SendChatMessage(text,"WHISPER",nil,otherPlayer);
end--end local function reply

--do animation letting them know it is their turn
local function setCheckersTurn(boolean)
if (boolean == true) then
setStatusText("Your Turn!",8);
else
setStatusText("Their Turn!",8);
end
isMyCheckersTurn = boolean;
end


function slashCheckers(msg, editBox)
local command, rest = msg:match("^(%S*)%s*(.-)$");
local targetName = "";
if (command == "") then
targetName = GetUnitName("target",true);
else

otherPlayer = command;
targetName = command;

end--end manual
if targetName and checkersMode == MODE_WAITING_FOR_REQUESTS and targetName ~= GetUnitName("player",true)
 then 
print("|cff8888ff[Checkers] Sending game request to " .. targetName .. " . . .");
doTheyAlsoHaveTheAddon = 0;--begin timer
isHostingTheCheckersGame = true;
isMyCheckersTurn = true;
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

local function leaveTheGame(reason)
if (reason == nil) then
reason = "User clicked the exit button";
end

if (checkersMode ~= MODE_PLAYING) then return end;-- so no interference
backgroundFrame:Hide();
bgDragFrame:Hide();
if (MainMenuBar) then MainMenuBar:Show(); end
reply(CHECKERS_LEAVING_MESSAGE);
print("|cff8888ff[Checkers] " .. reason);
--delete all of the pieces?
setCheckersMode(MODE_WAITING_FOR_REQUESTS);
end--end local function leaveTheGame

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
otherPlayer = author;

isHostingTheCheckersGame = false;
reply(CHECKERS_REQUEST_ACKNOWLEDGED);
setCheckersMode(MODE_ANSWERING_REQUEST);
putConfirmationBox();
end--end request message
if (message == CHECKERS_LEAVING_MESSAGE) then
leaveTheGame("Other player left the game");
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

end
--[[
function isValidMove - returns 2 values
returns (booleanValid [, takenPieceIndex])
--]]
local function isValidMove(thisPiece, r1, c1, r2, c2, team, king)
--handle the attempted movement of pieces that are just display.
if (thisPiece ~= -1 and pieces[thisPiece].alive == false) then return false; end

--make sure it's player's turn.
if (isMyCheckersTurn == false) then
setStatusText("It is their turn.",8,VOICE_WRONG_TURN);
return false
end;
--check board boundaries
if (r2 <= 0 or r2 >= 9 or c2 <= 0 or c2 >= 9) then
setStatusText("Out of bounds",8,VOICE_OUT_OF_RANGE);
return false;
end--end out of board bounds
--check if r2,c2 is occupied
if (isSpaceOccupied(r2,c2) ~= -1) then
setStatusText("Space is taken",8,VOICE_INVALID_MOVE);
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

setStatusText("Nope",8,VOICE_INVALID_MOVE);
return false;--default case
end--end isValidMove

function thereAreValidTakesForPiece(i)

--if king then can take either way
--otherwise 
--do each corner.
r = pieces[i].row;
c = pieces[i].column;
king = pieces[i].king;
team = pieces[i].team;
--local function isValidMove(thisPiece, r1, c1, r2, c2, team, king)
return (isValidMove(i,r,c,r-2,c-2,team,king)
	or
	isValidMove(i,r,c,r-2,c+2,team,king)
	or
	isValidMove(i,r,c,r+2,c+2,team,king)
	or
	isValidMove(i,r,c,r+2,c-2,team,king)
	);
end--end function thereAreValidTakesForPiece


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
checkerFrame;
tx = nil;
};

local kids = {backgroundFrame:GetChildren()};
if (firstCheckerRun == true) then
pieces[i].checkerFrame = CreateFrame("FRAME", "checkerFrame" .. i,
								backgroundFrame);
else--begin firstCheckerRun == false
--find the handle on the existing frame, and align it with this data.
for _,checker in ipairs(kids) do
local name = checker:GetName();
local index = tonumber(string.sub(name,strlen("checkerFrame")+1));
if (index == i) then
pieces[i].checkerFrame = checker;
end--end if index == i
end--end for iterator
end--end firstCheckerRun == false

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
isValid, takenIndex = isValidMove(i,pieces[i].row,pieces[i].column,
		landedRow,landedColumn, pieces[i].team,pieces[i].king);
if (isValid == false and isAPieceTakeTurn == true) then
setStatusText("You must take a piece.",8,VOICE_INVALID_MOVE);
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
		setStatusText("Still your turn -- take next piece",8);
		else
		--done taking pieces. end the turn.
		endMyturn = 1;
		isAPieceTakeTurn = false;
		setStatusText("Turn ended",4);
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
end--end isOneOfMyPiecesSoLetMeMoveIt
pieces[i].checkerFrame:SetPoint("BOTTOMLEFT",(c-1)*widthB/8,(r-1)*heightB/8);
pieces[i].checkerFrame:SetSize(widthB/8,heightB/8);
pieces[i].tx = pieces[i].checkerFrame:CreateTexture();
pieces[i].tx:SetAllPoints();
pieces[i].tx:SetAlpha(1);
if (pieces[i].team == TEAM_HOST) then
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/alliance_checker.tga');
else
pieces[i].tx:SetTexture('Interface/AddOns/Checkers/images/horde_checker.tga');
end
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


firstCheckerRun = false;--the frames have all been instantiated.
end--end function createPieces

function populateCheckersSounds()
local placeHolder = "";
--chooses array assignment based on faction
checkersVoices = isHostingTheCheckersGame and {
VOICE_WRONG_TURN = {
--i cant do that yet
"Sound\\Character\\NightElf\\NightElfMaleErrorMessages\\NightElfMale_err_abilitycooldown02.ogg"
},
VOICE_INVALID_MOVE = {
--i cant put that there
"Sound\\Character\\NightElf\\NightElfMaleErrorMessages\\NightElfMale_err_ammoonly02.ogg",
"Sound\\Character\\Draenei\\DraeneiMale_Err_AmmoOnly01.ogg",
"Sound\\Character\\Dwarf\\DwarfMaleErrorMessages\\DwarfMale_err_ammoonly02.ogg",
"Sound\\Character\\Gnome\\GnomeMaleErrorMessages\\GnomeMale_err_ammoonly02.ogg",
"Sound\\Character\\Human\\MaleErrorMessages\\HumanMale_err_ammoonly02.ogg",
},
VOICE_FRIENDLY_PIECE_TAKEN = {
--roars
"Sound/character/Draenei/DraeneiMaleRoar01.ogg",
"Sound/character/Dwarf/DwarfVocalMale/VO_PCDwarfMaleRoar01.ogg",
"Sound/character/Gnome/GnomeVocalMale/VO_PCGnomeMaleRoar01.ogg",
"Sound/character/Human/HumanVocalMale/VO_PCHumanMaleRoar01.ogg",
"Sound/character/NightElf/NightElfVocalMale/VO_PCNightElfMaleRoar01.ogg",
"Sound/character/PCWorgenMale/VO_PCWorgenMale_Roar01.ogg"


},
VOICE_ENEMY_PIECE_TAKEN = {
"Sound/character/BloodElf/BloodElfMaleRoar01.ogg",
"Sound/character/Orc/OrcVocalMale/VO_PCOrcMaleRoar01.ogg",
"Sound/character/PCGilneanMale/VO_PCGilneanMale_Roar01.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar01.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar02.ogg",
"Sound/character/PCGoblinMale/VO_PCGoblinMale_Roar03.ogg"
},
VOICE_FRIENDLY_PIECE_KINGED = {
	--alliance king noises
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_01-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_02-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_03-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_04-01.OGG",
"Sound/creature/KingVarianWrynn/VO_5.1_ALP_Varian_Greet_05-01.OGG",
"Sound/creature/VarianWrynn/CR_Varian_AArrival01.ogg",
"Sound/creature/VarianWrynn/CR_Varian_AArrival02.ogg",
"Sound/creature/VarianWrynn/CR_Varian_AArrival03.ogg"

},
VOICE_ENEMY_PIECE_KINGED = {
	--horde king noises
"Sound/creature/GARROSH/CR_Garrosh_HArrival01.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival02.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival03.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival04.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival05.ogg"
},
VOICE_FRIENDLY_KING_TAKEN = {
"Sound/creature/VarianWrynn/CR_Varian_KillH01.ogg",
"Sound/creature/VarianWrynn/CR_Varian_KillH02.ogg",
"Sound/creature/VarianWrynn/CR_Varian_KillH03.ogg",
"Sound/creature/VarianWrynn/CR_Varian_KillH04.ogg"

},
VOICE_ENEMY_KING_TAKEN = {
"Sound/creature/GARROSH/CR_Garrosh_Death02.ogg"
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
"Sound/character/Human/MaleErrorMessages/HumanMale_err_loottoofar02.ogg",
"Sound/character/Human/MaleErrorMessages/HumanMale_err_loottoofar03.ogg",
"Sound/character/Human/MaleErrorMessages/HumanMale_err_loottoofar04.ogg",
"Sound/character/NightElf/NightElfMaleErrorMessages/NightElfMale_err_loottoofar02.ogg",
"Sound/character/NightElf/NightElfMaleErrorMessages/NightElfMale_err_loottoofar03.ogg",
"Sound/character/NightElf/NightElfMaleErrorMessages/NightElfMale_err_loottoofar04.ogg"

}
} or--end alliance voice table
{
VOICE_WRONG_TURN = {
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_abilitycooldown01.ogg",
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_abilitycooldown02.ogg",
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_abilitycooldown03.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_abilitycooldown01.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_abilitycooldown02.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_abilitycooldown03.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_abilitycooldown01.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_abilitycooldown02.ogg",
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_abilitycooldown03.ogg"
},
VOICE_INVALID_MOVE = {
"Sound/character/Tauren/TaurenMaleErrorMessages/TaurenMale_err_ammoonly02.ogg",
"Sound/character/Orc/OrcMaleErrorMessages/OrcMale_err_ammoonly02.ogg",
"Sound/character/Troll/TrollMaleErrorMessages/TrollMale_err_ammoonly02.ogg",
"Sound/character/Scourge/ScourgeMaleErrorMessages/UndeadMale_err_ammoonly02.ogg"
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
"Sound/creature/GARROSH/CR_Garrosh_HArrival01.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival02.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival03.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival04.ogg",
"Sound/creature/GARROSH/CR_Garrosh_HArrival05.ogg"
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
}

};--end horde voice table


end--end function populateCheckersSounds

function startCheckers()
setCheckersMode(MODE_PLAYING);
createPieces();
populateCheckersSounds();
--draw the frames
popframe:Hide();
if (MainMenuBar) then MainMenuBar:Hide(); end
backgroundFrame:ClearAllPoints();
bgDragFrame:ClearAllPoints();
bgDragFrame:SetPoint("TOP");
backgroundFrame:SetPoint("TOP",0,-25);
backgroundFrame:SetSize(widthB,heightB);
bgDragFrame:SetSize(widthB,25);
backgroundFrame:SetFrameStrata('MEDIUM');
backgroundFrame:Show(); 
bgDragFrame:Show();

end--end function startCheckers

local function acceptButtonPressed()
reply(CHECKERS_ACCEPT_REQUEST_MESSAGE);
setCheckersMode(MODE_PLAYING);
isMyCheckersTurn = false;
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
exitCheckersFrame:SetScript("OnClick", leaveTheGame;
exitCheckersFrame:SetBackdropColor(0,0,1);
exitCheckersFrame:Show();
end--end Checkers_initialize

function Checkers_OnLoad()
print("|cff8888ff[Checkers] addon loaded! Type '/Checkers' while targeting a player to play against them. They must also have the addon: |cffffff00www.curse.com/addons/wow/checkers");
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",CheckersIncoming);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CheckersOutgoing);
end--end Checkers_OnLoad



