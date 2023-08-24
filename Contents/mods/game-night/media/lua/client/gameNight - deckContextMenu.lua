require "ISUI/ISInventoryPaneContextMenu"
local itemManipulation = require "gameNight - itemManipulation"
local deckActionHandler = require "gameNight - deckActionHandler"

local deckContext = {}

deckContext.gameNightContextMenuIcon = getTexture("media/textures/gamenight_icon.png")

function deckContext.addInventoryItemContext(player, context, items)
    for _, v in ipairs(items) do

        local item = v
        if not instanceof(v, "InventoryItem") then item = v.items[1] end

        itemManipulation.applyGameNightToItem(item)
        local deck, flippedStates = deckActionHandler.getDeck(item)

        if deck then
            if #deck>1 then
                context:addOption(getText("IGUI_drawCard"), item, deckActionHandler.drawCard)
                context:addOption(getText("IGUI_drawRandCard"), item, deckActionHandler.drawRandCard)
                context:addOption(getText("IGUI_shuffleCards"), item, deckActionHandler.shuffleCards)
            end
            context:addOption(getText("IGUI_flipCard"), item, deckActionHandler.flipCard)
            break
        end
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(deckContext.addInventoryItemContext)


require "gameNight - window"
function deckContext.addWorldContext(playerID, context, worldObjects)
    local playerObj = getSpecificPlayer(playerID)
    local square

    for _,v in ipairs(worldObjects) do square = v:getSquare() end
    if not square then return end

    if (math.abs(playerObj:getX()-square:getX())>2) or (math.abs(playerObj:getY()-square:getY())>2) then return end

    local validObjectCount = 0

    for i=0,square:getObjects():size()-1 do
        ---@type IsoObject|IsoWorldInventoryObject
        local object = square:getObjects():get(i)
        if object and instanceof(object, "IsoWorldInventoryObject") then
            local item = object:getItem()
            if item and item:getTags():contains("gameNight") then
                validObjectCount = validObjectCount+1
            end
        end
    end

    if validObjectCount > 0 then
        local option = context:addOptionOnTop(getText("IGUI_Play_Game"), worldObjects, gameNightWindow.open, playerObj, square)
        option.iconTexture = deckContext.gameNightContextMenuIcon
    end
end
Events.OnFillWorldObjectContextMenu.Add(deckContext.addWorldContext)

return deckContext