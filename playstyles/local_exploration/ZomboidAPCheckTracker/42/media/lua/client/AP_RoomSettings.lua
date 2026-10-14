-- F10: configure the bundled Windows bridge. Room server, not generation seed, connects to AP.
require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
local cfgFile="APCheckTracker_room.txt"
local function readCfg()
    local v={"","ZomboidPlayer","",""}
    if not getFileReader then return v end
    pcall(function()
        local f=getFileReader(cfgFile,false)
        if not f then return end
        if f:readLine()=="APROOM_V1" then
            for i=1,4 do v[i]=f:readLine() or v[i] end
        end
        f:close()
    end)
    return v
end
local Window=ISCollapsableWindow:derive("APRoomSettingsWindow")
function Window:new(x,y)
    local o=ISCollapsableWindow.new(self,x,y,490,246)
    o.title="Archipelago Room Setup (F10)"
    o.resizable=false
    o.moveWithMouse=true
    return o
end
function Window:createChildren()
    ISCollapsableWindow.createChildren(self)
    local values=readCfg()
    local labels={"Server (wss://host:port)","Slot name","Room password (optional)"}
    self.fields={}
    for i=1,3 do
        local y=34+(i-1)*52
        local lbl=ISLabel:new(14,y,18,labels[i],1,1,1,1,UIFont.Small,true)
        lbl:initialise(); self:addChild(lbl)
        local entry=ISTextEntryBox:new(values[i],14,y+20,460,25)
        entry:initialise(); entry:instantiate(); self:addChild(entry)
        self.fields[i]=entry
    end
    self.saveButton=ISButton:new(14,207,150,26,"Save settings",self,self.save)
    self.saveButton:initialise(); self.saveButton:instantiate(); self:addChild(self.saveButton)
end
function Window:save()
    local v={}
    for i=1,3 do
        v[i]=self.fields[i]:getText():gsub("[\r\n]","")
    end
    v[4]="" -- legacy placeholder, actual seed comes from Archipelago server
    if v[1]=="" or v[2]=="" then
        print("[APRoom] Enter a server address and slot name")
        return
    end
    local ok,err=pcall(function()
        local f=getFileWriter(cfgFile,true,false)
        if not f then error("No file writer") end
        f:write("APROOM_V1\n")
        for i=1,4 do f:write(v[i].."\n") end
        f:close()
    end)
    if not ok then print("[APRoom] Save failed: "..tostring(err))
    else print("[APRoom] Saved room settings. Start or restart Start-Archipelago-Bridge.bat") end
end
local active=nil
local function openWindow()
    if isClient and isClient() then return end
    if active then active:setVisible(true); active:addToUIManager(); return end
    active=Window:new(200,120)
    active:initialise(); active:instantiate(); active:addToUIManager()
end
local wasDown=false
local function onKeyPressed(key)
    if key==68 then openWindow() end -- Keyboard.KEY_F10 is 68 in LWJGL; fallback below
end
if Events and Events.OnKeyPressed then
    Events.OnKeyPressed.Add(function(key)
        if Keyboard and key==Keyboard.KEY_F10 then openWindow()
        elseif not Keyboard and key==68 then openWindow() end
    end)
end
print("[APRoom] F10 room setup loaded")
