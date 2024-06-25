--- For anyone looking to make a sub-mod:
--- ! SEE: `gameNight - implementUno` for a simpler example on adding decks.
--- CATAN includes 'game pieces' rather than *just* cards - scroll to the bottom for more info on those.

local applyItemDetails = require "gameNight - applyItemDetails"
local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceAndBoardHandler = applyItemDetails.gamePieceAndBoardHandler


-- CARDS
--- CATAN RESOURCES DECK
local CatanResourceDeck = {}
CatanResourceDeck.types = {"Brick","Stone","Wood","Wheat","Sheep"}
CatanResourceDeck.cards = {}

for _,s in pairs(CatanResourceDeck.types) do for i=1, 19 do table.insert(CatanResourceDeck.cards, s) end end
deckActionHandler.addDeck("CatanResourceDeck", CatanResourceDeck.cards)

--- CATAN DEVELOPMENTS DECK
local CatanDevelopmentDeck = {}

--Five (5) Victory Point Cards (Chapel, Library, Market, Palace, University).
CatanDevelopmentDeck.cards = {"Chapel", "Library", "Market", "Palace", "University"}

--Fourteen (14) Knight Cards.
--Six (6) Progress Cards (2 x Monopoly, 2 x Road Building, 2 x Year of Plenty).
CatanDevelopmentDeck.types = {"Knight","Monopoly","Road Building","Year of Plenty"}
CatanDevelopmentDeck.count = {14,2,2,2}

for i,s in pairs(CatanDevelopmentDeck.types) do for ii=1, CatanDevelopmentDeck.count[i] do table.insert(CatanDevelopmentDeck.cards, s) end end
deckActionHandler.addDeck("CatanDevelopmentDeck", CatanDevelopmentDeck.cards)


-- GAME PIECES / GAME BOARD

---Register game pieces by type -- enables the system to display the items using custom textures found in:
--- `Item_InPlayTextures` and `Item_OutOfPlayTextures`
--- Note: In-Play defaults to Out of play textures. Out of play textures replaces the item's texture/icon.
gamePieceAndBoardHandler.registerTypes({
    "Base.CatanCityWhite", "Base.CatanSettlementWhite", "Base.CatanRoadWhite",
    "Base.CatanCityRed", "Base.CatanSettlementRed", "Base.CatanRoadRed",
    "Base.CatanCityBlue", "Base.CatanSettlementBlue", "Base.CatanRoadBlue",
    "Base.CatanCityOrange", "Base.CatanSettlementOrange", "Base.CatanRoadOrange",
    "Base.CatanRobber", "Base.CatanLongestRoad", "Base.CatanLargestArmy", "Base.CatanBoard",
    "Base.CatanPlayerCostsWhite", "Base.CatanPlayerCostsRed", "Base.CatanPlayerCostsOrange", "Base.CatanPlayerCostsBlue"})

---Register special cases for modifying parts of the item
--- For example, the board is registered to the game-system above - which turns it into a 'GamePiece'
--- This `special` case changes the category from `GamePiece` to `GameBoard`.
gamePieceAndBoardHandler.registerSpecial("Base.CatanBoard", { actions = { lock=true }, category = "GameBoard", textureSize = {768,676} })

gamePieceAndBoardHandler.registerSpecial("Base.CatanCityWhite", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.CatanCityRed", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.CatanCityBlue", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.CatanCityOrange", { noRotate=true, })

gamePieceAndBoardHandler.registerSpecial("Base.CatanSettlementWhite", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.CatanSettlementRed", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.CatanSettlementBlue", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.CatanSettlementOrange", { noRotate=true, })

gamePieceAndBoardHandler.registerSpecial("Base.CatanRobber", { noRotate=true, })

gamePieceAndBoardHandler.registerSpecial("Base.CatanRoadWhite", {
    actions = { rotateRoad=true }, shiftAction = "rotateRoad",
    alternateStackRendering = { func="DrawTextureCardFace", depth=5, rgb = {0.741, 0.725, 0.710} } })

gamePieceAndBoardHandler.registerSpecial("Base.CatanRoadRed", {
    actions = { rotateRoad=true }, shiftAction = "rotateRoad",
    alternateStackRendering = { func="DrawTextureCardFace", depth=5, rgb = {0.651, 0.353, 0.373} } })

gamePieceAndBoardHandler.registerSpecial("Base.CatanRoadBlue", {
    actions = { rotateRoad=true }, shiftAction = "rotateRoad",
    alternateStackRendering = { func="DrawTextureCardFace", depth=5, rgb = {0.376, 0.439, 0.529} } })

gamePieceAndBoardHandler.registerSpecial("Base.CatanRoadOrange", {
    actions = { rotateRoad=true }, shiftAction = "rotateRoad",
    alternateStackRendering = { func="DrawTextureCardFace", depth=5, rgb = {0.745, 0.588, 0.408} } })

---Define new function under `gamePieceAndBoardHandler`
function gamePieceAndBoardHandler.rotateRoad(gamePiece, player)
    local current = gamePiece:getModData()["gameNight_rotation"] or 0

    local states = {[0]=45,[45]=90,[90]=135,[135]=180,[180]=225,[225]=270,[270]=315,[315]=0}
    local state = states[current]

    if not state then
        local closest = false
        for id,angle in pairs(states) do
            if (not closest) or (closest and math.abs(angle-current) < states[closest]) then
                closest = id
            end
        end
        state = states[closest]
    end

    gamePieceAndBoardHandler.playSound(gamePiece, player)
    gamePieceAndBoardHandler.pickupAndPlaceGamePiece(player, gamePiece, {gamePieceAndBoardHandler.setModDataValue, gamePiece, "gameNight_rotation", state})
end
