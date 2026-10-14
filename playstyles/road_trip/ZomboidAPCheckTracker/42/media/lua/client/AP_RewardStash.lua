-- B42 AP reward stash: F9, no auto-delivery, claimed indices saved in Global ModData.
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
local SAVE_KEY="APRewardStash_v16"
local function activeRunKey()
    -- Session file is written ONLY after the bridge verifies the server seed and slot.
    if not getFileReader then return nil end
    local room=getFileReader("APCheckTracker_room.txt",false)
    if not room then return nil end
    if room:readLine() ~= "APROOM_V1" then room:close(); return nil end
    local server=room:readLine() or ""
    local slot=room:readLine() or ""
    room:close()
    if server=="" or slot=="" then return nil end
    if not server:match("^wss?://") then server="wss://"..server end
    local session=getFileReader("APCheckTracker_session.txt",false)
    if not session then return nil end
    local header=session:readLine()
    local sessionServer=session:readLine() or ""
    local sessionSlot=session:readLine() or ""
    local key=session:readLine() or ""
    session:close()
    if header~="APSESSION_V1" or key=="" then return nil end
    if not sessionServer:match("^wss?://") then sessionServer="wss://"..sessionServer end
    if string.lower(server) ~= string.lower(sessionServer) or string.lower(slot) ~= string.lower(sessionSlot) then return nil end
    return key
end
local rewards={}
local window=nil
local tick=0
local function state()
    if not ModData or not ModData.getOrCreate then return nil end
    local d=ModData.getOrCreate(SAVE_KEY)
    d.runs=d.runs or {}
    local key=activeRunKey()
    if not key then return nil end
    d.runs[key]=d.runs[key] or {claimed={}}
    return d.runs[key]
end
local function player()
    if isClient and isClient() then return nil end
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end
-- Never trust a reward snapshot unless a live, authenticated bridge refreshes its heartbeat.
-- Old snapshots remain on disk safely but are not visible or claimable offline.
local function bridgeIsLive()
    if not getFileReader or not os or not os.time then return false end
    local f=getFileReader("APCheckTracker_live.txt",false)
    if not f then return false end
    local line=f:readLine() or ""
    f:close()
    local key=activeRunKey()
    if not key then return false end
    local prefix="APLIVE_V1|"..key.."|"
    if line:sub(1,#prefix)~=prefix then return false end
    local stamp=tonumber(line:sub(#prefix+1))
    local now=os.time()
    return stamp~=nil and stamp<=now+3 and stamp>=now-10
end
local function parseRewards()
    if not bridgeIsLive() then rewards={}; return end
    if not getFileReader then rewards={}; return end
    local ok,err=pcall(function()
        local f=getFileReader("APCheckTracker_rewards.txt",false)
        if not f then rewards={}; return end
        local header=f:readLine()
        local key=activeRunKey()
        if not key or header~=("APREWARDS_V3|"..key) then
            f:close()
            rewards={} -- stale snapshot or settings changed; never display old rewards
            return
        end
        local parsed={}
        while true do
            local line=f:readLine()
            if not line then break end
            local index,id,qty,sender=line:match("^(%d+)|([%w%.]+)|(%d+)|([%w_%-]*)$")
            if index and id and qty then
                local n=tonumber(index); local q=tonumber(qty)
                if n and q and q>=1 and q<=20 and id:match("^Base%.[%w_]+$") then
                    parsed[#parsed+1]={index=n,id=id,qty=q,sender=sender or ""}
                end
            end
        end
        f:close()
        rewards=parsed
    end)
    if not ok then print("[APStash] Read error: "..tostring(err)) end
end
local function claim(reward)
    local p=player(); local d=state()
    if not bridgeIsLive() or not p or not d or not reward or d.claimed[tostring(reward.index)] then return false end
    local inventory=p:getInventory()
    if not inventory then return false end
    -- Prevent partial claims by using a single AddItems call. Failed adds leave it unclaimed.
    local ok,result=pcall(function() return inventory:AddItems(reward.id,reward.qty) end)
    if not ok or not result then
        print("[APStash] Could not loot "..tostring(reward.id))
        return false
    end
    d.claimed[tostring(reward.index)]=true
    print("[APStash] LOOTED #"..tostring(reward.index).." "..reward.id.." x"..reward.qty)
    return true
end
local Stash=ISCollapsableWindow:derive("APRewardStashWindow")
function Stash:new(x,y,w,h)
    local o=ISCollapsableWindow.new(self,x,y,w,h)
    o.title="Archipelago Reward Stash"
    o.resizable=true; o.moveWithMouse=true
    return o
end
function Stash:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.list=ISScrollingListBox:new(12,56,self.width-24,self.height-112)
    self.list:initialise(); self.list:instantiate(); self.list.itemheight=30
    self.list.drawBorder=true; self:addChild(self.list)
    self.loot=ISButton:new(12,self.height-46,120,28,"Loot Selected",self,self.lootSelected)
    self.loot:initialise(); self.loot:instantiate(); self:addChild(self.loot)
    self.lootAll=ISButton:new(142,self.height-46,100,28,"Loot All",self,self.lootEverything)
    self.lootAll:initialise(); self.lootAll:instantiate(); self:addChild(self.lootAll)
    self:refreshRewards()
end
function Stash:refreshRewards()
    if not self.list then return end
    local d=state(); self.list:clear(); local pending=0
    for _,r in ipairs(rewards) do
        if not d or not d.claimed[tostring(r.index)] then
            pending=pending+1
            self.list:addItem("#"..r.index.."  "..r.id.." x"..r.qty.."  (from "..r.sender..")",r)
        end
    end
    self.pending=pending
end
function Stash:lootSelected()
    if self.list and self.list.items and self.list.selected and self.list.items[self.list.selected] then
        claim(self.list.items[self.list.selected].item)
    end
    self:refreshRewards()
end
function Stash:lootEverything()
    local d=state()
    for _,r in ipairs(rewards) do
        if d and not d.claimed[tostring(r.index)] then claim(r) end
    end
    self:refreshRewards()
end
function Stash:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawText("Pending rewards: "..tostring(self.pending or 0).."  |  F9 to toggle",12,33,1,1,1,1,UIFont.Small)
    if self.list then self.list:setWidth(self.width-24); self.list:setHeight(self.height-112) end
    if self.loot then self.loot:setY(self.height-46) end
    if self.lootAll then self.lootAll:setY(self.height-46) end
end
local function toggle()
    if window then
        local visible=not window:getIsVisible()
        window:setVisible(visible)
        if visible then window:addToUIManager(); parseRewards(); window:refreshRewards() end
        return
    end
    window=Stash:new(170,130,570,420)
    window:initialise(); window:instantiate(); window:addToUIManager()
    parseRewards(); window:refreshRewards()
end
local function onKey(key)
    if Keyboard and key==Keyboard.KEY_F9 then
        local ok,err=pcall(toggle)
        if not ok then print("[APStash] UI error: "..tostring(err)) end
    end
end
local function onTick()
    tick=tick+1
    if tick<300 then return end
    tick=0
    parseRewards()
    if window and window:getIsVisible() then
        local ok,err=pcall(function() window:refreshRewards() end)
        if not ok then print("[APStash] Refresh error: "..tostring(err)) end
    end
end
if Events and Events.OnKeyPressed then Events.OnKeyPressed.Add(onKey) end
if Events and Events.OnTick then Events.OnTick.Add(onTick) end
print("[APStash] F9 reward stash loaded (v1.6 server-seed isolation)")
