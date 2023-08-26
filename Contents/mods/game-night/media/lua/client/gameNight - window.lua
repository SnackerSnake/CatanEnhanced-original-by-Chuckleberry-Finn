require "ISUI/ISPanelJoypad"
require "gameNight - gameElement"

---@class gameNightWindow : ISPanel
gameNightWindow = ISPanelJoypad:derive("gameNightWindow")

gameNightWindow.elements = {}

function gameNightWindow:initialise()
    ISPanelJoypad.initialise(self)

    local btnWid = 100
    local btnHgt = 25
    local padBottom = 10

    self.close = ISButton:new(self.padding, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("UI_Close"), self, gameNightWindow.onClick)
    self.close.internal = "CLOSE"
    self.close.borderColor = {r=1, g=1, b=1, a=0.4}
    self.close:initialise()
    self.close:instantiate()
    self:addChild(self.close)

    local playerNum = self.player:getPlayerNum()

    local inventory = getPlayerInventory(playerNum)
    if inventory then inventory:refreshBackpacks() end

    local loot = getPlayerLoot(playerNum)
    if loot then loot:refreshBackpacks() end
end


function gameNightWindow:onClick(button) if button.internal == "CLOSE" then self:setVisible(false) end end


function gameNightWindow:processMouseUp(old, x, y)
    if self.movingPiece then self.movingPiece:moveElement(self.movingPiece:getMouseX(), self.movingPiece:getMouseY()) end
    old(self, x, y)
end
function gameNightWindow:onMouseUpOutside(x, y) self:processMouseUp(ISPanelJoypad.onMouseUpOutside, x, y) end
function gameNightWindow:onMouseUp(x, y) self:processMouseUp(ISPanelJoypad.onMouseUp, x, y) end


function gameNightWindow:onMouseDown(x, y)
    self.moveWithMouse = ((x < self.bounds.x1) or (y < self.bounds.y1) or (x > self.bounds.x2) or (y > self.bounds.y2))
    ISPanelJoypad.onMouseDown(self, x, y)
end


function gameNightWindow:getClickedPriorityPiece(x, y, clicked)
    local offsetX, offsetY = clicked and clicked.x or 0, clicked and clicked.y or 0
    local cursorX, cursorY = x+offsetX, y+offsetY

    local selection = clicked
    for item,element in pairs(self.elements) do
        if element:isVisible() then
            local inBounds = ((cursorX >= element.x) and (cursorY >= element.y) and (cursorX <= element.x+element.width) and (cursorY <= element.y+element.height))
            if inBounds and ((not selection) or element.priority > selection.priority) then
                selection = element
            end
        end
    end

    return selection
end


---@param item IsoObject|InventoryItem
---@param object IsoObject|IsoWorldInventoryObject
function gameNightWindow:generateElement(item, object, priority)
    ---@type gameNightElement
    local element = self.elements[item]
    local x = (object:getWorldPosX()-object:getX()) * (self.width-(self.padding*2))
    local y = (object:getWorldPosY()-object:getY()) * (self.height-(self.padding*2))

    ---@type Texture
    local texture = item:getModData()["gameNight_textureInPlay"] or item:getTexture()
    local w, h = texture:getWidth(), texture:getHeight()

    if not element then
        self.elements[item] = gameNightElement:new(x, y, w, h, item)
        element = self.elements[item]
        element:addToUIManager()
    end

    if element then

        element:setVisible(true)
        element:setX(self.x+x)
        element:setY(self.y+y)
        element:drawTextureScaledAspect(texture, 0, 0, w, h, 1, 1, 1, 1)
        element.priority = priority
    end
end


function gameNightWindow.compareElements(a, b)
    return (a.object:getWorldPosY() < b.object:getWorldPosY()) and ((a.item:getDisplayCategory() == b.item:getDisplayCategory()) or (a.item:getDisplayCategory() ~= "GameBoard" and b.item:getDisplayCategory() ~= "GameBoard"))
end

function gameNightWindow:bringToTop()
    ISPanelJoypad.bringToTop(self)
    for item,element in pairs(self.elements) do element:bringToTop() end
end


function gameNightWindow:prerender()
    ISPanelJoypad.prerender(self)
    for item,element in pairs(self.elements) do element:setVisible(false) end

    ---@type IsoGridSquare
    local square = self.square
    if not square then return end

    self:drawRectBorder(self.padding, self.padding, (self.width-(self.padding*2)), (self.height-(self.padding*2)), 0.8, 0.8, 0.8, 0.8)

    local loadOrder = {}
    for i=0, square:getObjects():size()-1 do
        ---@type IsoObject|IsoWorldInventoryObject
        local object = square:getObjects():get(i)
        if object and instanceof(object, "IsoWorldInventoryObject") then
            local item = object:getItem()
            if item and item:getTags():contains("gameNight") then
                local position = item:getDisplayCategory() == "GameBoard" and 1 or #loadOrder+1
                table.insert(loadOrder, position, {item=item, object=object})
            end
        end
    end
    table.sort(loadOrder, gameNightWindow.compareElements)

    for priority,stuff in pairs(loadOrder) do self:generateElement(stuff.item, stuff.object, priority) end
end


function gameNightWindow:render()
    ISPanelJoypad.render(self)
    local movingElement = self.movingPiece
    if movingElement then
        if not isMouseButtonDown(0) then return end
        local selfW, selfH = movingElement:getWidth(), movingElement:getHeight()
        local texture = movingElement.itemObject:getModData()["gameNight_textureInPlay"] or movingElement.itemObject:getTexture()
        movingElement:drawTexture(texture, movingElement:getMouseX()-(selfW), movingElement:getMouseY()-(selfH), 0.55, 1, 1, 1)
    end
end


function gameNightWindow.open(self, player, square)

    if not gameNightWindow.instance then
        gameNightWindow:new(nil, nil, 500, 500, player, square)
        gameNightWindow.instance:initialise()
        gameNightWindow.instance:addToUIManager()
    end
    gameNightWindow.instance.square = square
    gameNightWindow.instance:setVisible(true)

    return gameNightWindow.instance
end


function gameNightWindow:new(x, y, width, height, player, square)
    local o = {}
    x = x or getCore():getScreenWidth()/2 - (width/2)
    y = y or getCore():getScreenHeight()/2 - (height/2)
    o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.3}

    o.width = width
    o.height = height
    o.player = player
    o.square = square

    o.padding = 45
    o.bounds = {x1=o.padding, y1=o.padding, x2=o.width-o.padding, y2=o.height-o.padding}

    --o.moveWithMouse = true
    o.selectedItem = nil
    o.pendingRequest = false

    gameNightWindow.instance = o

    return o
end