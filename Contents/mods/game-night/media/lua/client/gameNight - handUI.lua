require "ISUI/ISPanel"
require "ISUI/ISPanelJoypad"
require "gameNight - window"

local applyItemDetails = require "gameNight - applyItemDetails"
local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceAndBoardHandler = applyItemDetails.gamePieceAndBoardHandler

---@class gameNightHand : ISPanel
gameNightHand = ISPanel:derive("gameNightHand")
gameNightHand.instance = false

function gameNightHand:closeAndRemove()
    local cardExamine = self.cardExamine
    if cardExamine then cardExamine:closeAndRemove() end

    self:setVisible(false)
    self:removeFromUIManager()
    gameNightHand.instance = nil
end


function gameNightHand:update()
    if (not self.player) or (not self.deck) then self:closeAndRemove() return end

    ---@type InventoryItem
    local item = self.deck
    ---@type IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
    local player = self.player

    local values,flipped = deckActionHandler.getDeckStates(item)
    if not values or #values < 1 then self:closeAndRemove() return end

    if item ~= player:getPrimaryHandItem() then self:closeAndRemove() return end

    local playerInv = self.player:getInventory()
    if playerInv:contains(item) then return end

    local outerMostCont = item:getOutermostContainer()
    local contParent = outerMostCont and outerMostCont:getParent()
    local contParentSq = contParent and contParent:getSquare()
    if contParentSq and ( contParentSq:DistToProper(self.player) > 2 ) then
        self:closeAndRemove()
        return
    end

    ---@type IsoWorldInventoryObject|IsoObject
    local worldItem = item:getWorldItem()
    local worldItemSq = worldItem and worldItem:getSquare()
    if worldItemSq and ( worldItemSq:DistToProper(self.player) > 2 ) then
        self:closeAndRemove()
        return
    end
end


function gameNightHand:onMouseWheel(del)
    if self.hiddenHeight > 0 then self.scrollY = math.max(0,math.min(self.hiddenHeight, (self.scrollY or 0)+(del*24))) end
    return true
end


function gameNightHand:getCardAtXY(x, y)
    local halfPad = math.floor((self.padding/2)+0.5)

    if x < halfPad or x > self.cardDisplay.width-halfPad then return end
    if y < halfPad or y > self.cardDisplay.height-halfPad then return end

    local colFactor = math.floor(((self.cardDisplay.width-self.padding) / (self.cardWidth+halfPad)) + 0.5)
    y = y + (self.scrollY or 0)

    local colMod = (x-halfPad) % (self.cardWidth+halfPad)
    local rowMod = (y-halfPad) % (self.cardHeight+halfPad)

    --if colMod > self.cardWidth then return end
    if rowMod > self.cardHeight then return end

    local col = math.floor( (x-halfPad) / (self.cardWidth+halfPad) )
    local row = math.floor( (y-halfPad) / (self.cardHeight+halfPad) )

    --print("x:",x,"  y:",y,"    col:",col," (",colMod,")    row:",row," (",rowMod,")")

    local cardData, _ = deckActionHandler.getDeckStates(self.deck)
    local selected = #cardData - math.floor(col + (row*colFactor))

    return selected, (colMod > self.cardWidth)
end


function gameNightHand:clearDragging()
    self.dragging = nil
    self.draggingOver = nil
    self.dragInBetween = nil
end


function gameNightHand:cardOnRightMouseUp(x, y)
    local searchWindow = self.parent
    local selected, _ = searchWindow:getCardAtXY(x, y)
    if selected then
        local context = ISContextMenu.get(searchWindow.player:getPlayerNum(), getMouseX(), getMouseY())
        context:addOption(getText("IGUI_draw"), searchWindow.deck, deckActionHandler.drawSpecificCard, searchWindow.player, selected)
        context:addOption(getText("IGUI_flipCard"), searchWindow.deck, deckActionHandler.flipSpecificCard, searchWindow.player, selected)
    end
    searchWindow:clearDragging()
end


function gameNightHand:onMouseMove(dx, dy)
    if not self:isMouseOver() then return end

    ---@type gameNightWindow
    local gameNightWin = gameNightWindow.instance
    local piece = gameNightWin and gameNightWin.movingPiece

    if self.dragging or piece then
        local x = self.cardDisplay:getMouseX()
        local y = self.cardDisplay:getMouseY()
        local selected, inBetween = self:getCardAtXY(x, y)

        self.draggingOver = selected
        self.dragInBetween = inBetween
    end
    ISPanel.onMouseMove(self, dx, dy)
end


function gameNightHand:cardOnMouseUpOutside(x, y)
    local searchWindow = self.parent

    ---@type gameNightWindow
    local gameNightWin = gameNightWindow.instance
    if gameNightWin and gameNightWin:isMouseOver() then
        local deckItem = searchWindow.deck
        local cardBeingDragged = searchWindow.dragging

        local cardDrawn = deckActionHandler._drawCardIndex(deckItem, cardBeingDragged)
        if cardDrawn then gameNightWin:calculateItemDrop(gameNightWin:getMouseX(), gameNightWin:getMouseY(), {cardDrawn}) end
    end

    searchWindow:clearDragging()
end


function gameNightHand:cardOnMouseUp(x, y)
    local searchWindow = self.parent

    local selection, _ = searchWindow:getCardAtXY(x, y)
    local deckItem = searchWindow.deck
    local cardData, flippedStates = deckActionHandler.getDeckStates(deckItem)

    if searchWindow.dragging and selection and selection >= 1 then
        local cardA, flippedA = cardData[searchWindow.dragging], flippedStates[searchWindow.dragging]
        if searchWindow.dragInBetween then
            local selectionDrag = -1
            if searchWindow.dragging < selection then
                selectionDrag = 1
                selection = selection-1
            end

            for n=searchWindow.dragging, selection, selectionDrag do
                local nextCard, nextFlip = cardData[n+selectionDrag], flippedStates[n+selectionDrag]
                cardData[n] = nextCard
                flippedStates[n] = nextFlip
            end

            cardData[selection] = cardA
            flippedStates[selection] = flippedA
        else
            local cardB, flippedB = cardData[selection], flippedStates[selection]

            cardData[searchWindow.dragging] = cardB
            flippedStates[searchWindow.dragging] = flippedB

            cardData[selection] = cardA
            flippedStates[selection] = flippedA
        end
        gamePieceAndBoardHandler.playSound(deckItem, searchWindow.player)
        deckActionHandler.handleDetails(deckItem)
    end

    searchWindow:clearDragging()
end


function gameNightHand:cardOnMouseDownOutside(x, y)
    local searchWindow = self.parent
    searchWindow:clearDragging()
end


function gameNightHand:cardOnMouseDown(x, y)
    local searchWindow = self.parent
    local selected, _ = searchWindow:getCardAtXY(x, y)
    searchWindow.dragging = selected
end


function gameNightHand:prerender() ISPanel.prerender(self) end

---gameNightHand.sizedOnce
function gameNightHand:render()
    self.cardDisplay:setStencilRect(0, 0, self.cardDisplay.width, self.cardDisplay.height)
    ISPanel.render(self)
    local cardData, cardFlipStates = deckActionHandler.getDeckStates(self.deck)

    local itemType = self.deck:getType()
    local fullType = self.deck:getFullType()
    local special = gamePieceAndBoardHandler.specials[fullType]
    local cardFaceType = special and special.cardFaceType or itemType

    local halfPad = math.floor((self.padding/2)+0.5)
    local xOffset, yOffset = halfPad, halfPad
    local resetXOffset = xOffset

    local specialCase = fullType and gamePieceAndBoardHandler.specials[fullType]
    local specialTextureSize = specialCase and specialCase.textureSize

    if #cardData < 1 then return end

    for n=#cardData, 1, -1 do

        local card = cardData[n]
        local flipped = cardFlipStates[n]

        if card then

            local textureToUse = deckActionHandler.fetchAltIcon(card, self.deck)

            local texturePath = (flipped and "media/textures/Item_"..itemType.."/FlippedInPlay.png") or "media/textures/Item_"..cardFaceType.."/"..textureToUse..".png"
            local origTexture = getTexture(texturePath)
            if origTexture then

                local w = specialTextureSize and specialTextureSize[1] or origTexture:getWidth()
                local h = specialTextureSize and specialTextureSize[2] or origTexture:getHeight()

                local tmpTexture = w and h and Texture.new(origTexture)
                if tmpTexture then
                    tmpTexture:setHeight(h)
                    tmpTexture:setWidth(w)
                end

                local texture = tmpTexture or origTexture

                if not self.cardHeight or not self.cardWidth then
                    self.cardHeight = h*0.5
                    self.cardWidth = w*0.5
                end

                if self.cardWidth+xOffset > self.cardDisplay.width+halfPad then

                    if not self.sizedOnce then
                        self.sizedOnce = true
                        self.cardDisplay:setWidth(self.cardWidth+xOffset+halfPad)
                        self:setWidth(self.cardDisplay.width+(self.padding*2))
                    end

                    xOffset = resetXOffset
                    yOffset = yOffset+self.cardHeight+halfPad
                end

                self.cardDisplay:drawTextureScaledUniform(texture, xOffset, yOffset-(self.scrollY or 0), 0.5, 1, 1, 1, 1)
                if self.dragging or self.draggingOver then

                    if self.dragging and self.dragging == n then
                        self.cardDisplay:drawRectBorder(xOffset, yOffset-(self.scrollY or 0), self.cardWidth, self.cardHeight, 1, 0.4, 0.6, 0.9)
                    elseif self.draggingOver and self.draggingOver == n then

                        local x = self.dragInBetween and xOffset+self.cardWidth or xOffset
                        local w = self.dragInBetween and 4 or self.cardWidth
                        local a = self.dragInBetween and 0.9 or 0.3
                        self.cardDisplay:drawRect(x, yOffset-(self.scrollY or 0), w, self.cardHeight, a, 0.4, 0.6, 0.9)
                    end
                end
            end
            xOffset = xOffset+self.cardWidth+halfPad
        end
    end
    self.hiddenHeight = math.max(0, yOffset-(self.cardDisplay.height-halfPad-self.cardHeight))
    self.cardDisplay:clearStencilRect()

    if self:isMouseOver() then
        local mouseX, mouseY = self.cardDisplay:getMouseX(), self.cardDisplay:getMouseY()
        local selected, _ = self:getCardAtXY(mouseX, mouseY)
        local sandbox = SandboxVars.GameNight.DisplayItemNames

        local cardExamine = self.cardExamine
        if cardExamine and ((not selected) or (not cardExamine.index) or (cardExamine.index ~= selected)) then cardExamine:closeAndRemove() end

        if sandbox and selected and selected>0 then
            local card = cardData[selected]
            local flipped = cardFlipStates[selected]

            local cardName = flipped and (getTextOrNull("IGUI_"..self.deck:getType()) or getItemNameFromFullType("Base."..self.deck:getType())) or deckActionHandler.fetchAltName(card, self.deck, special)
            if cardName then
                local cardNameW = getTextManager():MeasureStringX(UIFont.NewSmall, " "..cardName.." ")
                local cardNameH = getTextManager():getFontHeight(UIFont.NewSmall)
                self.cardDisplay:drawRect(mouseX+(cardNameW/3), mouseY-cardNameH, cardNameW, cardNameH, 0.7, 0, 0, 0)
                self.cardDisplay:drawTextCentre(cardName, mouseX+(cardNameW*0.833), mouseY-cardNameH, 1, 1, 1, 0.7, UIFont.NewSmall)
            end

            if specialCase and specialCase.actions and specialCase.actions.examineCard and (not self.cardExamine) then
                if deckActionHandler.isDeckItem(self.deck) then
                    self.cardExamine = gameNightCardExamine.open(self.player, self.deck, false, selected, self)
                end
            end
        end
    else
        local cardExamine = self.cardExamine
        if cardExamine then cardExamine:closeAndRemove() end
    end

end


function gameNightHand:initialise()
    ISPanel.initialise(self)

    local pd = self.padding
    self.bounds = {x1=pd, y1=(pd*2), x2=self.width-pd, y2=self.height-pd}

    self.cardDisplay = ISPanelJoypad:new(self.bounds.x1, self.bounds.y1, self.bounds.x2-self.padding, self.bounds.y2-(self.padding*2))
    self.cardDisplay:initialise()
    self.cardDisplay:instantiate()
    self.cardDisplay.onMouseDown = self.cardOnMouseDown
    self.cardDisplay.onMouseDownOutside = self.cardOnMouseDownOutside
    self.cardDisplay.onMouseUp = self.cardOnMouseUp
    self.cardDisplay.onMouseUpOutside = self.cardOnMouseUpOutside
    self.cardDisplay.onRightMouseUp = self.cardOnRightMouseUp

    self:addChild(self.cardDisplay)
end



function gameNightHand.open(player, deckItem)

    local instance = gameNightHand.instance
    if instance then instance:closeAndRemove() end

    local gameWindow = gameNightWindow and gameNightWindow.instance
    local x, y, w, h
    if gameWindow then
        x = (gameWindow:getX())
        y = (gameWindow:getY()+gameWindow:getHeight())
        w = gameWindow:getWidth()
    end

    local window = gameNightHand:new(x, y, w, 160, player, deckItem)
    window:initialise()
    window:setAlwaysOnTop(true)
    window:addToUIManager()
    window:setVisible(true)

    return window
end



function gameNightHand:new(x, y, width, height, player, deckItem)
    local o = {}
    x = x or getCore():getScreenWidth()/2 - (width/2)
    y = y or getCore():getScreenHeight()/2 - (height/2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.3}

    o.moveWithMouse = true

    o.width = width
    o.height = height

    o.player = player
    o.deck = deckItem

    o.padding = 10

    gameNightHand.instance = o
    return o
end