local deckActionHandler = require "gameNight - deckActionHandler"
local gamePieceAndBoardHandler = require "gameNight - gamePieceAndBoardHandler"

local applyItemDetails = {}

applyItemDetails.deckCatalogues = {}
applyItemDetails.altDetails = {} --altNames, altIcons

function applyItemDetails.addDeck(name, cards, altNames, altIcons)
    applyItemDetails.deckCatalogues[name] = cards

    if altNames or altIcons then
        applyItemDetails.altDetails[name] = {}
        if altNames then applyItemDetails.altDetails[name].altNames = altNames end
        if altIcons then applyItemDetails.altDetails[name].altIcons = altIcons end
    end
end


applyItemDetails.parsedItems = {}
function applyItemDetails.applyGameNightToItem(item)
    if not item then return end

    local gamePiece, deck

    if (not applyItemDetails.parsedItems[item]) then

        applyItemDetails.parsedItems[item] = true
        
        if not gamePieceAndBoardHandler._itemTypes then gamePieceAndBoardHandler.generate_itemTypes() end

        gamePiece = gamePieceAndBoardHandler.isGamePiece(item)
        if gamePiece then gamePieceAndBoardHandler.handleDetails(item) end

        local itemType = item:getType()

        deck = applyItemDetails.deckCatalogues[itemType]
        if deck then
            if deck then
                item:getModData()["gameNight_cardDeck"] = item:getModData()["gameNight_cardDeck"] or copyTable(deck)

                if applyItemDetails.altDetails[itemType] then
                    item:getModData()["gameNight_cardAltNames"] = applyItemDetails.altDetails[itemType].altNames
                    item:getModData()["gameNight_cardAltIcons"] = applyItemDetails.altDetails[itemType].altIcons
                end

                local flippedStates = item:getModData()["gameNight_cardFlipped"]
            if not flippedStates then
            item:getModData()["gameNight_cardFlipped"] = {}
                for i=1, #deck do item:getModData()["gameNight_cardFlipped"][i] = true end
                end
                deckActionHandler.handleDetails(item)
                end
        end
    end
end


---@param ItemContainer ItemContainer
function applyItemDetails.applyGameNightToInventory(ItemContainer)

    if not ItemContainer then return end
    local items = ItemContainer:getItems()
    for iteration=0, items:size()-1 do
        ---@type InventoryItem
        local item = items:get(iteration)
        applyItemDetails.applyGameNightToItem(item)
    end
end

function applyItemDetails.applyToInventory(ISInventoryPage, step)
    if step == "begin" then
        applyItemDetails.applyGameNightToInventory(ISInventoryPage.inventory)
    end
end

function applyItemDetails.applyToFillContainer(contName, contType, container)
    applyItemDetails.applyGameNightToInventory(container)
end

return applyItemDetails