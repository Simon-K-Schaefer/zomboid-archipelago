-- Build 42 single-player achievement viewer; toggle with F8.
-- Read-only: does not grant checks or change saved progress.
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"

local PREFIX = "[APCheckTrackerUI] "
local window = nil
local CATEGORIES = {combat="Combat",survival="Survival",skill="Skills",town="Exploration",vehicle="Vehicles",distance="Vehicles",item="Equipment",meta="Special",collect="Keepsakes & Projects",death="Survival"}
local ORDER = {"combat","survival","skill","town","vehicle","distance","item","collect","death","meta"}

local AchievementWindow = ISCollapsableWindow:derive("APAchievementWindow")

function AchievementWindow:new(x,y,w,h)
    local o = ISCollapsableWindow.new(self,x,y,w,h)
    o.title = "Archipelago Checks"
    o.resizable = true
    o.moveWithMouse = true
    return o
end

function AchievementWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function AchievementWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.list = ISScrollingListBox:new(12,54,self.width-24,self.height-66)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = 50
    self.list.drawBorder = true
    self.list.doDrawItem = self.drawAchievement
    self:addChild(self.list)
    self:refreshChecks()
end

function AchievementWindow:drawAchievement(y,item,alt)
    local data = item.item
    if not data then return y + self.itemheight end
    local done = data.completed
    local label = (done and "[X] " or "[ ] ") .. data.name
    local status = done and "Completed" or "In progress"
    local details = "ID " .. tostring(data.id) .. "  |  " .. status
    if not done and type(data.progress) == "number" then
        local progress = math.floor(data.progress)
        details = details .. "  |  " .. tostring(progress) .. "/" .. tostring(data.target)
        if data.category == "survival" then details = details .. " in-game hours" end
        if data.category == "distance" then details = details .. " meters" end
    end
    local r,g,b = 0.8,0.8,0.8
    if done then r,g,b = 0.55,0.9,0.6 end
    self:drawText(label,8,y+3,r,g,b,1,UIFont.Small)
    self:drawText(tostring(data.description or ""),18,y+19,0.9,0.85,0.68,1,UIFont.Small)
    self:drawText(details,18,y+35,0.7,0.7,0.7,1,UIFont.Small)
    return y + self.itemheight
end

function AchievementWindow:refreshChecks()
    if not self.list then return end
    self.list:clear()
    local getter = _G.APCheckTracker_GetSnapshot
    if type(getter) ~= "function" then
        self.summary = "Tracker not initialized yet"
        return
    end
    local ok, snapshot = pcall(getter)
    if not ok or not snapshot then
        self.summary = "Waiting for game save..."
        return
    end
    self.summary = (snapshot.profile or "Unknown") .. " | " .. tostring(snapshot.completed) .. " / " .. tostring(snapshot.total) .. " completed"
    for _, category in ipairs(ORDER) do
        for _, entry in ipairs(snapshot.entries) do
            if entry.category == category then
                -- Keep categories grouped while preserving stable check IDs.
                self.list:addItem(CATEGORIES[category] .. ": " .. entry.name,entry)
            end
        end
    end
end

function AchievementWindow:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawText("Achievements: " .. (self.summary or "Loading...") .. "   |   F8 to toggle",12,32,1,1,1,1,UIFont.Small)
    if self.list then
        self.list:setWidth(self.width-24)
        self.list:setHeight(self.height-66)
    end
end

local function toggleWindow()
    if window then
        if window:getIsVisible() then
            window:setVisible(false)
        else
            window:setVisible(true)
            window:addToUIManager()
            window:refreshChecks()
        end
        return
    end
    local width,height = 610,570
    local x,y = 100,100
    if getCore then
        local core = getCore()
        if core then
            x = math.max(10,math.floor((core:getScreenWidth()-width)/2))
            y = math.max(10,math.floor((core:getScreenHeight()-height)/2))
        end
    end
    window = AchievementWindow:new(x,y,width,height)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:refreshChecks()
    print(PREFIX .. "WINDOW_OPENED")
end

local function onKeyPressed(key)
    if Keyboard and key == Keyboard.KEY_F8 then
        local ok,err = pcall(toggleWindow)
        if not ok then print(PREFIX .. "ERROR opening window: " .. tostring(err)) end
    end
end

local function onTick()
    if not window or not window:getIsVisible() then return end
    window.refreshCounter = (window.refreshCounter or 0) + 1
    if window.refreshCounter >= 180 then
        window.refreshCounter = 0
        local ok,err = pcall(function() window:refreshChecks() end)
        if not ok then print(PREFIX .. "ERROR refreshing: " .. tostring(err)) end
    end
end

if Events and Events.OnKeyPressed then
    Events.OnKeyPressed.Add(onKeyPressed)
    print(PREFIX .. "LOADED v0.5-easy: press F8 to open achievements")
else
    print(PREFIX .. "ERROR OnKeyPressed event unavailable")
end
if Events and Events.OnTick then Events.OnTick.Add(onTick) end
