-- Project Zomboid Build 42 - Archipelago Check Tracker v0.2
-- SINGLE PLAYER ONLY. Global ModData stores completed checks; player modData stores
-- per-character diagnostic snapshots and legacy v0.1 state.
local AP_PROFILE_STYLE = "base_building"
local PREFIX = "[APCheckTracker] "
local SAVE_KEY = "APCheckTracker_v16_" .. AP_PROFILE_STYLE
local OLD_KEY = "APCheckTracker_v01"
local PLAYER_KEY = "APCheckTracker_character_v16_" .. AP_PROFILE_STYLE
local SCHEMA = 4

local checks = {
    {100001,"first_blood","First Blood","combat",1},
    {100004,"getting_started","Getting Started","combat",10},
    {100002,"zombie_hunter","Clearing the Block","combat",35},
    {100005,"exterminator","Neighborhood Defender","combat",80},
    {100006,"walking_apocalypse","The Last Stand","combat",150},
    {100003,"survivor","Survivor","survival",1},
    {100007,"still_breathing","First Night","survival",3},
    {100008,"one_day_later","Half a Day","survival",6},
    {100009,"one_week_later","Another Sunrise","survival",12},
    {100010,"long_haul","Second Day","survival",36},
    {100028,"two_weeks_later","One Full Day","survival",24},
    {100029,"first_ride","First Ride","vehicle",1},
    {100031,"road_trip","Supply Run","distance",2500},
    {100034,"armed_and_dangerous","Armed and Dangerous","item",1,"firearm"},
    {100035,"heavy_hitter","Heavy Hitter","item",1,"sledgehammer"},
    {100036,"prepared_survivor","Prepared Survivor","item",1,"firstaid"},
    {100038,"well_equipped","Well Equipped","item",1,"backpack"},
    {100045,"world_traveler","World Traveler","meta",5},
    {100011,"apprentice_carpenter","Carpentry Basics","skill",1,"Woodwork"},
    {100012,"skilled_carpenter","Home Improver","skill",2,"Woodwork"},
    {100013,"master_carpenter","Safehouse Builder","skill",3,"Woodwork"},
    {100014,"camp_cook","First Cooked Meal","skill",1,"Cooking"},
    {100015,"professional_cook","Camp Chef","skill",2,"Cooking"},
    {100016,"master_chef","Kitchen Regular","skill",3,"Cooking"},
    {100017,"amateur_mechanic","Grease Monkey","skill",1,"Mechanics"},
    {100018,"experienced_mechanic","Garage Apprentice","skill",2,"Mechanics"},
    {100019,"master_mechanic","Roadside Mechanic","skill",3,"Mechanics"},
    {100020,"amateur_electrician","First Sparks","skill",1,"Electricity"},
    {100021,"experienced_electrician","Handy Electrician","skill",2,"Electricity"},
    {100022,"master_electrician","Electrical Tinkerer","skill",3,"Electricity"},
    {100023,"welcome_riverside","Welcome to Riverside","town",0,"Riverside"},
    {100024,"rosewood_tourist","Rosewood Tourist","town",0,"Rosewood"},
    {100025,"west_point_explorer","West Point Explorer","town",0,"West Point"},
    {100026,"muldraugh_resident","Muldraugh Resident","town",0,"Muldraugh"},
    {100027,"big_city_life","Big City Life","town",0,"Louisville"},
    {100064,"ap_100064","A Piece of Home","collect",1,"diary"},
    {100065,"ap_100065","Family Album","collect",1,"photobook"},
    {100066,"ap_100066","The Last Broadcast","collect",1,"homevhs"},
    {100067,"ap_100067","Spiffo Was Here","collect",1,"spiffopen"},
    {100068,"ap_100068","A Friend for the End","collect",1,"spiffoplush"},
    {100069,"ap_100069","A Promise Kept","collect",1,"weddingring"},
    {100070,"ap_100070","Childhood Memories","collect",1,"toy"},
    {100071,"ap_100071","Stories Worth Saving","collect",1,"comic"},
    {100072,"ap_100072","Preserve the Past","collect",1,"memorypair"},
    {100073,"ap_100073","Time Capsule","collect",1,"timecapsule"},
    {100074,"ap_100074","Lights On","collect",1,"powerkit"},
    {100075,"ap_100075","The Workshop","collect",1,"workshop"},
    {100076,"ap_100076","Fortify the Homestead","collect",1,"fortify"},
    {100077,"ap_100077","The Last Mechanic","collect",1,"garage"},
    {100078,"ap_100078","A Place to Remember","collect",1,"heirlooms"},
    {100079,"one_last_lesson","One Last Lesson","death",1},
    {100080,"foundationsupplies","Foundation Supplies","collect",1,"planksnails"},
    {100081,"buildkitcomplete","Build Kit Complete","collect",1,"buildkit"},
    {100082,"reinforcementmaterials","Reinforcement Materials","collect",1,"metalreinforce"},
    {100083,"gardenbeginnings","Garden Beginnings","collect",1,"gardenset"},
    {100084,"homekitchen","Home Kitchen","collect",1,"homekitchen"},
    {100085,"backuppowerplan","Backup Power Plan","collect",1,"backuppower"},
    {100086,"cozycorner","Cozy Corner","collect",1,"cozycorner"},
    {100087,"homesteadready","Homestead Ready","collect",1,"homesteadready"},
    {100088,"medicalscavenge","Medical Scavenge","collect",1,"medscavenge"},
    {100089,"portablelibrary","Portable Library","collect",1,"portablelibrary"},
    {100090,"maptheblock","Map the Block","collect",1,"maptheblock"},
    {100091,"emergencystash","Emergency Stash","collect",1,"emergencystash"},
    {100092,"neighborhoodchronicle","Neighborhood Chronicle","collect",1,"neighborhoodchronicle"},
    {100093,"sparefuel","Spare Fuel","collect",1,"sparefuel"},
    {100094,"roadsideessentials","Roadside Essentials","collect",1,"roadsideessentials"},
    {100095,"emergencydetour","Emergency Detour","collect",1,"emergencydetour"},
    {100096,"packedhighway","Packed for the Highway","collect",1,"packedhighway"},
}

-- Only show and send checks belonging to the selected YAML playstyle.
local profileAllowed = {[100001]=true,[100003]=true,[100007]=true,[100008]=true,[100009]=true,[100028]=true,[100011]=true,[100012]=true,[100013]=true,[100014]=true,[100015]=true,[100016]=true,[100017]=true,[100018]=true,[100019]=true,[100020]=true,[100021]=true,[100022]=true,[100035]=true,[100036]=true,[100038]=true,[100064]=true,[100065]=true,[100069]=true,[100070]=true,[100071]=true,[100072]=true,[100073]=true,[100074]=true,[100075]=true,[100076]=true,[100078]=true,[100079]=true,[100080]=true,[100081]=true,[100082]=true,[100083]=true,[100084]=true,[100085]=true,[100086]=true,[100087]=true}
local fullChecks = checks
checks = {}
for _,entry in ipairs(fullChecks) do
    if profileAllowed[entry[1]] then checks[#checks+1] = entry end
end

-- Player-facing achievement descriptions. Keep keyed by stable IDs.
local descriptions = {
    [100001] = "Kill your first zombie.",
    [100004] = "Kill 10 zombies with one survivor.",
    [100002] = "Kill 35 zombies with one survivor.",
    [100005] = "Kill 80 zombies with one survivor.",
    [100006] = "Kill 150 zombies with one survivor.",
    [100003] = "Stay alive for 1 in-game hour.",
    [100007] = "Survive 3 in-game hours on one survivor.",
    [100008] = "Survive 6 in-game hours on one survivor.",
    [100009] = "Survive 12 in-game hours on one survivor.",
    [100010] = "Survive 36 in-game hours on one survivor.",
    [100028] = "Survive 24 in-game hours on one survivor.",
    [100029] = "Drive a moving vehicle as its driver.",
    [100031] = "Drive a total of 2.5 kilometers on one survivor.",
    [100034] = "Carry a firearm in your inventory.",
    [100035] = "Carry a sledgehammer in your inventory.",
    [100036] = "Carry a first aid kit in your inventory.",
    [100038] = "Equip a backpack on your back.",
    [100045] = "Complete the Riverside, Rosewood, West Point, Muldraugh and Louisville checks.",
    [100011] = "Reach Carpentry level 1 on one survivor.",
    [100012] = "Reach Carpentry level 2 on one survivor.",
    [100013] = "Reach Carpentry level 3 on one survivor.",
    [100014] = "Reach Cooking level 1 on one survivor.",
    [100015] = "Reach Cooking level 2 on one survivor.",
    [100016] = "Reach Cooking level 3 on one survivor.",
    [100017] = "Reach Mechanics level 1 on one survivor.",
    [100018] = "Reach Mechanics level 2 on one survivor.",
    [100019] = "Reach Mechanics level 3 on one survivor.",
    [100020] = "Reach Electrical level 1 on one survivor.",
    [100021] = "Reach Electrical level 2 on one survivor.",
    [100022] = "Reach Electrical level 3 on one survivor.",
    [100023] = "Enter the Riverside town check zone.",
    [100024] = "Enter the Rosewood town check zone.",
    [100025] = "Enter the West Point town check zone.",
    [100026] = "Enter the Muldraugh town check zone.",
    [100027] = "Enter the Louisville city check zone.",
    [100064] = "Find a personal diary or journal.",
    [100065] = "Find a photo book or picture book.",
    [100066] = "Recover a home VHS recording.",
    [100067] = "Find a genuine Spiffo pen.",
    [100068] = "Rescue a Spiffo plush toy.",
    [100069] = "Find a wedding ring.",
    [100070] = "Find a toy or teddy bear.",
    [100071] = "Find a comic book.",
    [100072] = "Collect a diary AND a photo or picture book.",
    [100073] = "Collect a diary, a comic book and a toy together.",
    [100074] = "Find a generator and an electrical manual or electronics magazine.",
    [100075] = "Collect a hammer, saw and box of nails together.",
    [100076] = "Collect a sledgehammer, hammer and nails together.",
    [100077] = "Collect a lug wrench, jack and wrench together.",
    [100078] = "Bring a photo book, a toy and a wedding ring together.",
    [100079] = "Die once. The lesson survives with the world save.",
    [100080] = "Carry planks and a box of nails.",
    [100081] = "Carry planks, nails, a saw and a hammer.",
    [100082] = "Carry sheet metal, nails and a hammer.",
    [100083] = "Carry seeds, a shovel and a watering can.",
    [100084] = "Carry a cooking pot and canned food.",
    [100085] = "Carry a generator and a gas can.",
    [100086] = "Carry a pillow and a book.",
    [100087] = "Carry planks, nails, a hammer, a saw and sheet metal together. This is a supply milestone, not detection of placed buildings.",
    [100088] = "Carry a first aid kit and bandages.",
    [100089] = "Carry a comic book and an ordinary book.",
    [100090] = "Carry a map and a pen.",
    [100091] = "Carry canned food and a water bottle.",
    [100092] = "Carry a diary, map and bandages together.",
    [100093] = "Carry a gas can.",
    [100094] = "Carry a lug wrench and a jack.",
    [100095] = "Carry a map and bandages.",
    [100096] = "Carry a gas can, a map and a first aid kit.",
}

-- Conservative INNER TOWN RECTANGLES, not exact administrative boundaries.
-- Based on published B42 map reference points; validate in-game before wider release.
-- Coordinates are world TILES (not map-grid cells). See README for references.
local towns = {
    Riverside = {6100, 5150, 6800, 5550},
    Rosewood = {7900, 11350, 8350, 11850},
    WestPoint = {11650, 6650, 12300, 7250},
    Muldraugh = {10300, 9100, 10900, 10600},
    Louisville = {12100, 1100, 13700, 3300},
}
local townKeys = {Riverside="Riverside", Rosewood="Rosewood", ["West Point"]="WestPoint", Muldraugh="Muldraugh", Louisville="Louisville"}

local state, initialized = nil, false
local ticks, lastPlayer = 0, nil
local warned = {}
local function log(s) print(PREFIX .. tostring(s)) end
local function warnOnce(k,s) if not warned[k] then warned[k]=true; log("WARNING "..s) end end
local function safeMethod(o, method)
    if not o then return nil end
    local ok, value = pcall(function() return o[method](o) end)
    if ok then return value end
    return nil
end
local function numberMethod(o, method)
    local v = safeMethod(o,method)
    if type(v)=="number" then return v end
    return nil
end
local function playerOrNil()
    if not getSpecificPlayer then return nil end
    return getSpecificPlayer(0)
end
local function getState()
    if state then return state end
    if not ModData or not ModData.getOrCreate then
        warnOnce("moddata","Global ModData API unavailable")
        return nil
    end
    local ok, data = pcall(function() return ModData.getOrCreate(SAVE_KEY) end)
    if not ok or type(data) ~= "table" then
        warnOnce("moddata","Could not load save-wide Global ModData")
        return nil
    end
    data.completed = data.completed or {}
    data.reported = data.reported or {} -- Reserved: only future server ACK should set this.
    data.schemaVersion = SCHEMA
    state = data
    return state
end
local function notify(player, label)
    local msg = "AP check: "..label
    local ok = pcall(function()
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player,msg)
        elseif player and player.Say then player:Say(msg) end
    end)
    if not ok then log("WARNING notification failed for "..label) end
end
local function completedCount(data)
    local n=0
    for _,c in ipairs(checks) do if data.completed[tostring(c[1])] then n=n+1 end end
    return n
end
local function complete(player, data, c, value)
    local id = tostring(c[1])
    if data.completed[id] then return end
    data.completed[id] = true
    log("CHECK_COMPLETE id="..id.." key="..c[2].." name="..c[3].." category="..c[4].." progress="..tostring(value).."/"..tostring(c[5]))
    notify(player,c[3])
end
local function migrate(player, data)
    local pd = safeMethod(player,"getModData")
    if type(pd) ~= "table" then return end
    local old = pd[OLD_KEY]
    if type(old) ~= "table" or type(old.completed) ~= "table" then return end
    local moved=0
    for _,id in ipairs({100001,100002,100003}) do
        if (old.completed[tostring(id)] or old.completed[id]) and not data.completed[tostring(id)] then
            data.completed[tostring(id)] = true
            moved=moved+1
        end
    end
    if moved>0 then log("MIGRATED v0.1 completed="..moved) end
    -- Mark per-character migration, but repeat safely for other old characters.
    pd[PLAYER_KEY] = pd[PLAYER_KEY] or {}
    pd[PLAYER_KEY].migratedV01 = true
end
local function skillLevel(player, skill)
    if not Perks then return nil end
    local perk = Perks[skill]
    if not perk and skill=="Woodwork" then perk=Perks.Carpentry end
    if not perk and skill=="Electricity" then perk=Perks.Electrical end
    if not perk then return nil end
    local ok, value = pcall(function() return player:getPerkLevel(perk) end)
    if ok and type(value)=="number" then return value end
    return nil
end
local function callArg(o, method, arg)
    if not o then return nil end
    local ok, v = pcall(function() return o[method](o,arg) end)
    if ok then return v end
    return nil
end
local function itemMatches(item, kind)
    local full = safeMethod(item,"getFullType")
    local typ = safeMethod(item,"getType")
    local name = tostring(full or typ or ""):lower()
    if kind == "sledgehammer" then return name:find("sledgehammer",1,true) ~= nil end
    if kind == "firstaid" then return name:find("firstaidkit",1,true) ~= nil end
    if kind == "firearm" then
        local cat = safeMethod(item,"getCategory")
        -- Build 42 does not reliably expose InventoryItem:isRanged().
        -- Use known vanilla firearm type names rather than calling a missing Java method.
        local firearmTypes = {
            pistol=true, pistol2=true, pistol3=true, revolver=true, revolver_long=true,
            revolvershort=true, revolverlong=true, shotgun=true, shotgun_sawn=true,
            doublebarrelshotgun=true, doublebarrelshotgun_sawn=true,
            assaultrifle=true, assaultrifle2=true, huntingrifle=true, varmintrifle=true,
            msr700=true, msr788=true, m14rifle=true, m16assaultRifle=true,
            handgun=true, handgun2=true, handgun3=true,
        }
        local short = tostring(typ or ""):lower()
        if firearmTypes[short] then return true end
        return tostring(cat) == "Weapon" and (
            name:find("pistol",1,true) ~= nil or name:find("revolver",1,true) ~= nil
            or name:find("shotgun",1,true) ~= nil or name:find("rifle",1,true) ~= nil
        ) and not name:find("airrifle",1,true)
    end
    return false
end
local function hasItem(player,kind)
    local inventory=safeMethod(player,"getInventory")
    if not inventory then return false end
    local items=safeMethod(inventory,"getItems")
    if not items then return false end
    local n=numberMethod(items,"size") or 0
    for i=0,math.min(n-1,2000) do
        local item=callArg(items,"get",i)
        if item and itemMatches(item,kind) then return true end
    end
    return false
end
local function hasBackpack(player)
    local item=safeMethod(player,"getClothingItem_Back")
    if not item then return false end
    local full=tostring(safeMethod(item,"getFullType") or ""):lower()
    return full:find("bag",1,true) ~= nil or full:find("backpack",1,true) ~= nil
end
local function driverVehicle(player)
    local vehicle=safeMethod(player,"getVehicle")
    if not vehicle then return nil end
    local driver=safeMethod(vehicle,"getDriver")
    if driver ~= player then return nil end
    return vehicle
end
local function charData(player)
    local pd=safeMethod(player,"getModData")
    if type(pd)~="table" then return nil end
    pd[PLAYER_KEY]=pd[PLAYER_KEY] or {}
    return pd[PLAYER_KEY]
end
local function updateDriving(player,cs)
    if not cs then return end
    local vehicle=driverVehicle(player)
    if not vehicle then
        cs.lastDriveX=nil; cs.lastDriveY=nil
        return
    end
    local x=numberMethod(vehicle,"getX")
    local y=numberMethod(vehicle,"getY")
    if not x or not y then return end
    local oldX,oldY=cs.lastDriveX,cs.lastDriveY
    if oldX and oldY then
        local dx,dy=x-oldX,y-oldY
        local dist=math.sqrt(dx*dx+dy*dy)
        -- World coordinates are tiles (~meters). Reject teleport / loading jumps.
        if dist > 0.15 and dist < 150 then
            cs.driveMeters=(tonumber(cs.driveMeters) or 0)+dist
            cs.hasDriven=true
        end
    end
    cs.lastDriveX=x;cs.lastDriveY=y
end

-- Research / keepsake checks: item names are deliberately checked against BOTH
-- Build 42 full type and display name. All required items must be carried at once.
-- Vanilla localization may change display names; see README for known limitations.
local collectTokens = {
    diary={"diary","journal"}, photobook={"photobook","picturebook","photo book","picture book"},
    homevhs={"home vhs","homevideo","vhs home","vhs_home"},
    spiffopen={"penspiffo","pen spiffo","spiffo pen"},
    spiffoplush={"spiffo plush","spiffoplush","plushie spiffo","plush spiffo"},
    weddingring={"weddingring","wedding ring"},
    toy={"teddybear","teddy bear","rubberduck","rubber duck","toycar","toy car"},
    comic={"comicbook","comic book"},
    generator={"base.generator","generator"},
    electricalbook={"electricity","electrical","electronics magazine"},
    hammer={"base.hammer","ballpeenhammer","clawhammer"},
    saw={"base.saw","handsaw"},
    nails={"nailsbox","box of nails"},
    sledgehammer={"sledgehammer"},
    lugwrench={"lugwrench","lug wrench"},
    jack={"base.jack","car jack"},
    wrench={"base.wrench","pipewrench","wrench"},
    planks={"base.plank","plank"},
    sheetmetal={"sheetmetal","sheet metal"},
    seeds={"seedpacket","seeds","seed packet","seedbag"},
    shovel={"base.shovel","shovel"},
    wateringcan={"wateringcan","watering can"},
    pot={"base.pot","cooking pot","saucepan"},
    cannedfood={"tinnedbeans","tinnedsoup","cannedfood","canned","tinned","tin of"},
    gascan={"petrolcan","gas can","gasoline can"},
    pillow={"base.pillow","pillow"},
    book={"base.book","book"},
    firstaid={"firstaidkit","first aid kit"},
    bandage={"base.bandage","bandage"},
    map={"map","road atlas"},
    pen={"base.pen","ballpoint pen","blue pen","red pen"},
    waterbottle={"waterbottle","water bottle","bottle of water"},
}
local collectRequirements = {
    diary={"diary"}, photobook={"photobook"}, homevhs={"homevhs"},
    spiffopen={"spiffopen"}, spiffoplush={"spiffoplush"}, weddingring={"weddingring"},
    toy={"toy"}, comic={"comic"}, memorypair={"diary","photobook"},
    timecapsule={"diary","comic","toy"}, powerkit={"generator","electricalbook"},
    workshop={"hammer","saw","nails"}, fortify={"sledgehammer","hammer","nails"},
    garage={"lugwrench","jack","wrench"}, heirlooms={"photobook","toy","weddingring"},
    planksnails={"planks","nails"},
    buildkit={"planks","nails","hammer","saw"},
    metalreinforce={"sheetmetal","nails","hammer"},
    gardenset={"seeds","shovel","wateringcan"},
    homekitchen={"pot","cannedfood"},
    backuppower={"generator","gascan"},
    cozycorner={"pillow","book"},
    homesteadready={"planks","nails","hammer","saw","sheetmetal"},
    medscavenge={"firstaid","bandage"},
    portablelibrary={"comic","book"},
    maptheblock={"map","pen"},
    emergencystash={"cannedfood","waterbottle"},
    neighborhoodchronicle={"diary","map","bandage"},
    sparefuel={"gascan"},
    roadsideessentials={"lugwrench","jack"},
    emergencydetour={"map","bandage"},
    packedhighway={"gascan","map","firstaid"},
}
local function hasCollectSet(player, key)
    local req=collectRequirements[key]
    if not req then return false end
    local inventory=safeMethod(player,"getInventory")
    local items=inventory and safeMethod(inventory,"getItems")
    if not items then return false end
    local found={}
    local n=numberMethod(items,"size") or 0
    for i=0,math.min(n-1,2000) do
        local item=callArg(items,"get",i)
        if item then
            local full=tostring(safeMethod(item,"getFullType") or ""):lower()
            local name=tostring(safeMethod(item,"getDisplayName") or ""):lower()
            for _,tag in ipairs(req) do
                if not found[tag] then
                    for _,token in ipairs(collectTokens[tag] or {}) do
                        if full:find(token,1,true) or name:find(token,1,true) then
                            -- Don't confuse a generic wrench with a lug wrench.
                            if (tag~="wrench" or not (full:find("lugwrench",1,true) or name:find("lug wrench",1,true)))
                                and (tag~="book" or not (full:find("comic",1,true) or name:find("comic",1,true))) then
                                found[tag]=true; break
                            end
                        end
                    end
                end
            end
        end
    end
    for _,tag in ipairs(req) do if not found[tag] then return false end end
    return true
end

local function townCount(data)
    local n=0
    for id=100023,100027 do if data.completed[tostring(id)] then n=n+1 end end
    return n
end
local function inRect(x,y,rect)
    return x>=rect[1] and x<=rect[3] and y>=rect[2] and y<=rect[4]
end
local function poll()
    if isClient and isClient() then
        warnOnce("mp","Multiplayer clients are not supported in v0.2")
        return
    end
    local player=playerOrNil()
    if not player then return end
    local data=getState()
    if not data then return end
    if player~=lastPlayer then
        lastPlayer=player
        -- v1.6 intentionally does not import ancient save checks into a new playstyle.
        log("READY schema="..SCHEMA.." completed="..completedCount(data).."/"..#checks)
    end
    local charState=charData(player)
    updateDriving(player,charState)
    local kills=numberMethod(player,"getZombieKills")
    if kills == nil then warnOnce("kills","getZombieKills unavailable") end
    local hours=numberMethod(player,"getHoursSurvived")
    if hours == nil then warnOnce("hours","getHoursSurvived unavailable") end
    if charState then
        charState.lastKills=kills or charState.lastKills
        charState.lastHours=hours or charState.lastHours
    end
    local levels={}
    local x=numberMethod(player,"getX")
    local y=numberMethod(player,"getY")
    if not x or not y then warnOnce("coords","getX/getY unavailable") end
    for _,c in ipairs(checks) do
        if not data.completed[tostring(c[1])] then
            if c[4]=="combat" and kills and kills>=c[5] then
                complete(player,data,c,kills)
            elseif c[4]=="survival" and hours and hours>=c[5] then
                complete(player,data,c,hours)
            elseif c[4]=="skill" then
                local skill=c[6]
                if levels[skill]==nil then levels[skill]=skillLevel(player,skill) or false end
                local level=levels[skill]
                if level==false then warnOnce("perk_"..skill,"Perk unavailable: "..skill)
                elseif level>=c[5] then complete(player,data,c,level) end
            elseif c[4]=="vehicle" and charState and charState.hasDriven then
                complete(player,data,c,1)
            elseif c[4]=="distance" and charState and (tonumber(charState.driveMeters) or 0)>=c[5] then
                complete(player,data,c,math.floor(charState.driveMeters))
            elseif c[4]=="item" then
                local found = (c[6]=="backpack") and hasBackpack(player) or hasItem(player,c[6])
                if found then complete(player,data,c,1) end
            elseif c[4]=="collect" and hasCollectSet(player,c[6]) then
                complete(player,data,c,1)
            elseif c[4]=="town" and x and y then
                local rect=towns[townKeys[c[6]]]
                if rect and inRect(x,y,rect) then
                    complete(player,data,c,"("..math.floor(x)..","..math.floor(y)..")")
                end
            end
        end
    end
    -- Resolve meta checks AFTER town checks, including the fifth town entered this tick.
    for _,c in ipairs(checks) do
        if c[4]=="meta" and not data.completed[tostring(c[1])] and townCount(data)>=c[5] then
            complete(player,data,c,townCount(data))
        end
    end
end
-- Read-only snapshot for the optional achievement window. No state mutation.
_G.APCheckTracker_GetSnapshot = function()
    local data = getState()
    if not data then return nil end
    local player = playerOrNil()
    local kills = player and numberMethod(player,"getZombieKills") or nil
    local hours = player and numberMethod(player,"getHoursSurvived") or nil
    local x = player and numberMethod(player,"getX") or nil
    local y = player and numberMethod(player,"getY") or nil
    local cs=player and charData(player) or nil
    local entries = {}
    for _, c in ipairs(checks) do
        local progress = nil
        if c[4] == "combat" then progress = kills
        elseif c[4] == "survival" then progress = hours
        elseif c[4] == "skill" and player then progress = skillLevel(player,c[6])
        elseif c[4] == "distance" and cs then progress = math.floor(tonumber(cs.driveMeters) or 0)
        elseif c[4] == "vehicle" and cs then progress = cs.hasDriven and 1 or 0
        elseif c[4] == "meta" then progress = townCount(data)
        elseif c[4] == "item" and player then
            progress = ((c[6]=="backpack") and hasBackpack(player) or hasItem(player,c[6])) and 1 or 0
        end
        entries[#entries+1] = {id=c[1],key=c[2],name=c[3],category=c[4],target=c[5],
            extra=c[6],description=descriptions[c[1]] or "Complete this check.",completed=(data.completed[tostring(c[1])] or data.completed[c[1]]) and true or false,
            progress=progress}
    end
    return {entries=entries,completed=completedCount(data),total=#checks,x=x,y=y,profile="Base Building"}
end

local function onTick()
    ticks=ticks+1
    if ticks<300 then return end -- ~5 seconds at 60 FPS; frame-dependent
    ticks=0
    local ok,err=pcall(poll)
    if not ok then log("ERROR poll: "..tostring(err)) end
end
local function onInitGlobalModData()
    state=nil
    lastPlayer=nil
    local data=getState()
    if data then log("GLOBAL_DATA_READY schema="..tostring(data.schemaVersion)) end
end
if Events and Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
end
if Events and Events.OnTick then
    Events.OnTick.Add(onTick)
    log("LOADED v0.5-easy B42 single-player; "..#checks.." checks; global save-wide persistence")
else
    log("ERROR Events.OnTick missing")
end

-- AP v0.7: export completed checks for the external Windows client.
local apLastExport = nil
local apProfileWritten = false
local function apExportProfile()
    if apProfileWritten or not getFileWriter then return end
    local ok = pcall(function()
        local f = getFileWriter("APCheckTracker_profile.txt",true,false)
        if not f then error("file writer unavailable") end
        f:write("APSTYLE_V1\n" .. AP_PROFILE_STYLE .. "\n")
        f:close()
    end)
    if ok then apProfileWritten=true end
end
local function apExportChecks()
    if not getFileWriter then return end
    local snapshot = _G.APCheckTracker_GetSnapshot and _G.APCheckTracker_GetSnapshot()
    if not snapshot then return end
    local ids = {}
    for _,entry in ipairs(snapshot.entries) do
        if entry.completed then ids[#ids+1] = entry.id end
    end
    table.sort(ids)
    local signature = AP_PROFILE_STYLE .. ":" .. table.concat(ids, ",")
    if signature == apLastExport then return end
    local ok,err = pcall(function()
        local w = getFileWriter("APCheckTracker_locations.txt", true, false)
        if not w then error("file writer unavailable") end
        w:write("APCHECKS_V2|" .. AP_PROFILE_STYLE .. "\n")
        for _,id in ipairs(ids) do w:write(tostring(id).."\n") end
        w:close()
    end)
    if ok then apLastExport=signature else print("[APBridge] Export error: "..tostring(err)) end
end
local apExportTicks=0
local function apExportTick()
    apExportTicks=apExportTicks+1
    if apExportTicks>=300 then apExportTicks=0; apExportProfile(); apExportChecks() end
end
if Events and Events.OnTick then Events.OnTick.Add(apExportTick) end

-- One Last Lesson: preserve the death check even if the player cannot tick again.
local function apOnPlayerDeath(player)
    local ok,err=pcall(function()
        local d=getState()
        if not d then return end
        for _,c in ipairs(checks) do
            if c[1]==100079 then complete(player,d,c,1); break end
        end
        apExportChecks()
    end)
    if not ok then print("[APCheckTracker] Death check error: "..tostring(err)) end
end
if Events and Events.OnPlayerDeath then Events.OnPlayerDeath.Add(apOnPlayerDeath) end
