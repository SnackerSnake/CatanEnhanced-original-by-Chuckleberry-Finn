local deckActionHandler = require "gameNight - deckActionHandler"
local gamePieceAndBoardHandler = require "gameNight - gamePieceAndBoardHandler"

local itemManipulation = {}

itemManipulation.catalogues = {}

function itemManipulation.addDeck(name, cards) itemManipulation.catalogues[name] = cards end


itemManipulation.parsedItems = {}
function itemManipulation.applyGameNightToItem(item)
    if not item then return end
    if (not itemManipulation.parsedItems[item]) then

        if not gamePieceAndBoardHandler._itemTypes then gamePieceAndBoardHandler.generate_itemTypes() end
        local gamePiece = gamePieceAndBoardHandler._itemTypes[item:getFullType()]
        if gamePiece then
            gamePieceAndBoardHandler.handleDetails(item)
        end

        local deck = itemManipulation.catalogues[item:getType()]
        if deck then
            itemManipulation.parsedItems[item] = true
            if deck then
                item:getModData()["gameNight_cardDeck"] = item:getModData()["gameNight_cardDeck"] or copyTable(deck)

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
function itemManipulation.applyGameNight(ItemContainer)

    if not ItemContainer then return end
    local items = ItemContainer:getItems()
    for iteration=0, items:size()-1 do
        ---@type InventoryItem
        local item = items:get(iteration)
        itemManipulation.applyGameNightToItem(item)
    end
end


function itemManipulation.applyToInventory(ISInventoryPage, step) if step == "begin" then itemManipulation.applyGameNight(ISInventoryPage.inventory) end end
Events.OnRefreshInventoryWindowContainers.Add(itemManipulation.applyToInventory)

function itemManipulation.applyToFillContainer(contName, contType, container) itemManipulation.applyGameNight(container) end
Events.OnFillContainer.Add(itemManipulation.applyToFillContainer)


return itemManipulation