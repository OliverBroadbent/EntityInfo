EntityInfo = {
    styler = {
        type = EXTENSION_TYPE.NBT_EDITOR_STYLE,
        recursive = true
    }
}

-- CUSTOM FUNCTIONS

function EntityInfo.styler:ticksToTime(ticks)
    local timeString = ""

    local secs = ticks/20
    local mins = (math.floor(secs))//60
    local hours = mins//60
    local days = hours//24

    if(days > 0) then timeString = timeString .. tostring(days) .. " days, " end
    if(hours > 0) then timeString = timeString .. tostring(hours%24) .. " hours, " end
    if(mins > 0) then timeString = timeString .. tostring(mins%60) .. " minutes, " end
    if(secs > 0) then timeString = timeString .. string.gsub(string.format("%.1f", math.abs(secs%60)), "%.0", "") .. " seconds" end

    return timeString
end

function EntityInfo.styler:colorToString(color)

    local colors = {
        {
            name = "White",
            qtColor = "white"
        },{
            name = "Orange",
            qtColor = "orange"
        },{
            name = "Magenta",
            qtColor = "magenta"
        },{
            name = "Light Blue",
            qtColor = "lightblue"
        },{
            name = "Yellow",
            qtColor = "yellow"
        },{
            name = "Lime",
            qtColor = "lime"
        },{
            name = "Pink",
            qtColor = "pink"
        },{
            name = "Gray",
            qtColor = "gray"
        },{
            name = "Light Gray",
            qtColor = "lightgray"
        },{
            name = "Cyan",
            qtColor = "cyan"
        },{
            name = "Purple",
            qtColor = "purple"
        },{
            name = "Blue",
            qtColor = "#2d32ff"
        },{
            name = "Brown",
            qtColor = "burlywood"
        },{
            name = "Green",
            qtColor = "green"
        },{
            name = "Red",
            qtColor = "red"
        },{
            name = "Black",
            qtColor = "black"
        }
    }

    return colors[color+1]

end

function EntityInfo.styler:getCustomNameJava(entity)
    
    if(entity:contains("CustomName", TYPE.STRING)) then
        local customName = entity.lastFound.value

        local jsonRoot = JSONValue.new()
        if(jsonRoot:parse(customName).type == JSON_TYPE.OBJECT) then
            local textOut = ""

            if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                textOut = jsonRoot.lastFound:getString()
            end

            if(jsonRoot:contains("extra", JSON_TYPE.ARRAY)) then
                local extraArray = jsonRoot.lastFound

                for j=0, extraArray.childCount-1 do
                    local extra = extraArray:child(j)
    
                    if(extra:contains("text", JSON_TYPE.STRING)) then
                        textOut = textOut .. extra.lastFound:getString()
                    end
                end
            end

            return textOut
        else
            return customName
        end
    end

    return ""
end

-- BASE ENTITY

function EntityInfo.styler:main(root, context)
    context.version = 0

    if(context.edition == EDITION.JAVA) then -- DataVersion
        if(root:contains("DataVersion", TYPE.INT)) then
            context.version = root.lastFound.value
        end
    end
    if((context.type & FILE_TYPE.PLAYER) ~= 0) then self:ProcessEntity(root, context) end
end

function EntityInfo.styler:recursion(root, target, context)

    if(context.edition == EDITION.JAVA) then
        if(target.type == TYPE.LIST and target.listType == TYPE.COMPOUND and (target.name == "Entities" or target.name == "Passengers")) then
            for i = 0, target.childCount-1 do self:ProcessEntity(target:child(i), context) end
        elseif(target.type == TYPE.COMPOUND and target.name == "SpawnData") then
            if(target:contains("entity", TYPE.COMPOUND)) then self:ProcessEntity(target.lastFound, context) end
        elseif(target.type == TYPE.LIST and target.listType == TYPE.COMPOUND and target.name == "SpawnPotentials") then
            for i = 0, target.childCount-1 do local temp1 = target:child(i)
                if(temp1:contains("data", TYPE.COMPOUND)) then local temp2 = temp1.lastFound
                    if(temp2:contains("entity", TYPE.COMPOUND)) then self:ProcessEntity(temp2.lastFound, context) end
                end
            end
        elseif(target.type == TYPE.COMPOUND and target.name == "Riding") then 
            self:ProcessEntity(target.lastFound, context) end
    elseif(context.edition == EDITION.BEDROCK) then
        if(target.type == TYPE.LIST and target.listType == TYPE.COMPOUND and (target.name == "Entities" or target.name == "Actors")) then
            for i = 0, target.childCount-1 do self:ProcessEntity(target:child(i), context) end
        end
    elseif(context.edition == EDITION.CONSOLE) then
        if(target.type == TYPE.LIST and target.listType == TYPE.COMPOUND and (target.name == "Entities" or target.name == "Riding")) then
            for i = 0, target.childCount-1 do self:ProcessEntity(target:child(i), context) end
        elseif(target.type == TYPE.COMPOUND and target.name == "SpawnData") then
            if(target:contains("entity", TYPE.COMPOUND)) then self:ProcessEntity(target.lastFound, context) end
        elseif(target.type == TYPE.LIST and target.listType == TYPE.COMPOUND and target.name == "SpawnPotentials") then
            for i = 0, target.childCount-1 do local temp1 = target:child(i)
                if(temp1:contains("data", TYPE.COMPOUND)) then local temp2 = temp1.lastFound
                    if(temp2:contains("entity", TYPE.COMPOUND)) then self:ProcessEntity(temp2.lastFound, context) end
                end
            end
        elseif(target.type == TYPE.COMPOUND and target.name == "Riding") then 
            self:ProcessEntity(target.lastFound, context)
        end
    end

end

function EntityInfo.styler:ProcessEntity(entity, context)
    self:NameAndIcon(entity, context)
    self:Position(entity, context)
    self:Rotation(entity, context)
    self:Motion(entity, context)
    self:Health(entity, context)
    self:Fire(entity, context)
    self:Air(entity, context)
    self:PortalCooldown(entity, context)
    self:ActiveEffects(entity, context)
    self:Attributes(entity, context)

    self:RunEntitySpecifics(entity, context)
end

function EntityInfo.styler:NameAndIcon(entity, context)

    if((context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) and entity:contains("id", TYPE.STRING)) then

        local dbEntry = Database:find(context.edition, "entities", entity.lastFound.value)
        if(not dbEntry.valid) then return end

        local entityName = dbEntry.name
        Style:setLabel(entity, entityName)
        Style:setLabelColor(entity, "#bfbfbf")
        entityName = entityName:gsub("[^%w]+", "")

        Style:setIcon(entity, "EntityInfo/images/entities/" .. entityName .. ".png")
    end

    if(context.edition == EDITION.BEDROCK) then

        local entityid = ""

        if(entity:contains("identifier", TYPE.STRING)) then
            entityid = entity.lastFound.value
        elseif(entity:contains("id", TYPE.STRING)) then
            entityid = entity.lastFound.value
        elseif(entity:contains("id", TYPE.INT)) then
            entityid = tostring(entity.lastFound.value & 255)
        else return end

        local dbEntry = Database:find(context.edition, "entities", entityid)
        if(not dbEntry.valid) then return end

        local entityName = dbEntry.name
        Style:setLabel(entity, entityName)
        Style:setLabelColor(entity, "#bfbfbf")
        entityName = entityName:gsub("%s+", "")

        Style:setIcon(entity, "EntityInfo/images/entities/" .. entityName .. ".png")
    end
end

function EntityInfo.styler:Position(entity, context)

    local listTypeCheck = TYPE.DOUBLE

    if(context.edition == EDITION.BEDROCK) then listTypeCheck = TYPE.FLOAT end
    if(entity:contains("Pos", TYPE.LIST, listTypeCheck)) then

        if(entity.lastFound.childCount == 3) then

            local pos = entity.lastFound

            Style:setLabelColor(pos, "#bfbfbf")
            Style:setLabel(pos, "X:" .. tostring(math.floor(pos:child(0).value + 0.5)) .. ", Y:" .. tostring(math.floor(pos:child(1).value + 0.5)) .. ", Z:" .. tostring(math.floor(pos:child(2).value + 0.5)))
            Style:setIcon(pos, "EntityInfo/images/Pos.png")
            Style:setLabel(pos:child(0), "X")
            Style:setLabel(pos:child(1), "Y")
            Style:setLabel(pos:child(2), "Z")
        end
    end
end

function EntityInfo.styler:Rotation(entity, context)

    if(entity:contains("Rotation", TYPE.LIST, TYPE.FLOAT)) then

        local rotString = ""
        local rot = entity.lastFound
        local yaw = rot:child(0)
        local pitch = rot:child(1)

        if(yaw.value > 337.5 or yaw.value <= 22.5) then rotString = rotString .. "Facing North"
        elseif(yaw.value > 22.5 and yaw.value <= 67.5) then rotString = rotString .. "Facing North-East"
        elseif(yaw.value > 67.5 and yaw.value <= 112.5) then rotString = rotString .. "Facing East"
        elseif(yaw.value > 112.5 and yaw.value <= 157.5) then rotString = rotString .. "Facing South-East"
        elseif(yaw.value > 157.5 and yaw.value <= 202.5) then rotString = rotString .. "Facing South"
        elseif(yaw.value > 202.5 and yaw.value <= 247.5) then rotString = rotString .. "Facing South-West"
        elseif(yaw.value > 247.5 and yaw.value <= 292.5) then rotString = rotString .. "Facing West"
        elseif(yaw.value > 292.5 and yaw.value <= 337.5) then rotString = rotString .. "Facing North-West"
        end
    
        if(pitch.value >= -90 and pitch.value < -45) then rotString = rotString .. " and Down"
        elseif(pitch.value >= 45 and pitch.value <= 90) then rotString = rotString .. " and Up"
        end
    
        Style:setLabelColor(rot, "#bfbfbf")
        Style:setLabel(rot, rotString)
        Style:setIcon(rot, "EntityInfo/images/Rot.png")
        Style:setLabel(rot:child(0), "Yaw")
        Style:setLabel(rot:child(1), "Pitch")
    end
end

function EntityInfo.styler:Motion(entity, context)

    if(entity:contains("Motion", TYPE.LIST, TYPE.DOUBLE)) then
        
        local motion = entity.lastFound
        
        if(motion.childCount == 3) then
        
            local x = motion:child(0)
            local y = motion:child(1)
            local z = motion:child(2)

            local xdir = ""
            local ydir = ""
            local zdir = ""

            local xlabel = "X"
            local ylabel = "Y"
            local zlabel = "Z"

            if(x.value ~= 0) then
                if(x.value < 0) then xdir = "West" elseif(x.value > 0) then xdir = "East" end
                xlabel = xlabel .. ": ".. string.gsub(string.format("%.1f", math.abs(x.value*20)), "%.0", "") .. "m/s " .. xdir
            end

            if(y.value ~= 0) then
                if(y.value < 0) then ydir = "Down" elseif(y.value > 0) then ydir = "Up" end
                ylabel = ylabel .. ": " .. string.gsub(string.format("%.1f", math.abs(y.value*20)), "%.0", "") .. "m/s " .. ydir
            end

            if(z.value ~= 0) then
                if(z.value < 0) then zdir = "South" elseif(z.value > 0) then zdir = "North" end
                zlabel = zlabel .. ": " .. string.gsub(string.format("%.1f", math.abs(z.value*20)), "%.0", "") .. "m/s " .. zdir
            end

            Style:setLabel(x, xlabel)
            Style:setLabel(y, ylabel)
            Style:setLabel(z, zlabel)            
        end
    end
end

function EntityInfo.styler:Health(entity, context)

    if(entity:contains("Health", TYPE.SHORT) or entity:contains("Health", TYPE.FLOAT)) then

        local health = entity.lastFound

        Style:setLabel(health, string.gsub(string.format("%.1f", health.value/2), "%.0", "") .. " Hearts")
        Style:setIcon(health, "EntityInfo/images/Health.png")
    end
end

function EntityInfo.styler:Fire(entity, context)

    if(entity:contains("Fire", TYPE.SHORT)) then

        local fire = entity.lastFound

        if(fire.value <= 0) then
            Style:setLabel(fire, "Not on fire")
        else
            Style:setLabel(fire, "Fire extinguishes in " .. self:ticksToTime(fire.value))
            Style:setIcon(fire, "EntityInfo/images/Fire.png")
        end

    end
end

function EntityInfo.styler:Air(entity, context)

    if(entity:contains("Air", TYPE.SHORT)) then

        local air = entity.lastFound

        if(air.value <= 0) then
            Style:setLabel(air, "Drowning")
        else
            Style:setLabel(air, self:ticksToTime(air.value) .. " of air")
        end
    end
end

function EntityInfo.styler:PortalCooldown(entity, context)

    if(entity:contains("PortalCooldown", TYPE.INT)) then

        local portalCooldown = entity.lastFound

        if(portalCooldown.value > 0) then
            Style:setLabel(portalCooldown, self:ticksToTime(portalCooldown.value))
        end
    end
end

function EntityInfo.styler:ActiveEffects(entity, context)
    if(entity:contains("ActiveEffects", TYPE.LIST, TYPE.COMPOUND)) then

        local activeEffects = entity.lastFound

        for i=0, activeEffects.childCount-1 do

            local activeEffect = activeEffects:child(i)
            local tagType = TYPE.BYTE

            if(context.edition == EDITION.JAVA and context.version >= 3080) then
                tagType = TYPE.INT
            end

            if activeEffect:contains("Id", tagType) then

                local dbEntry = Database:find(context.edition, "active_effects", tostring(activeEffect.lastFound.value))

                if(dbEntry.valid) then

                    local activeEffectName = dbEntry.name

                    Style:setLabel(activeEffect, activeEffectName)
                    Style:setLabelColor(activeEffect, "#bfbfbf")

                    activeEffectName = activeEffectName:gsub("[^%w]+", "")

                    Style:setIcon(activeEffect, "EntityInfo/images/effects/" .. activeEffectName .. ".png")
                end
            end
    
            if(activeEffect:contains("Duration", TYPE.INT)) then
                local time = activeEffect.lastFound
    
                if(time.value >= 0) then
                    Style:setLabel(time, self:ticksToTime(time.value))
                end
            end
        end
    end
end

function EntityInfo.styler:Attributes(entity, context)

    if(entity:contains("Attributes", TYPE.LIST, TYPE.COMPOUND)) then

        local attributes = entity.lastFound

        if(context.edition == EDITION.JAVA or context.edition == EDITION.BEDROCK) then 
            for i=0, attributes.childCount-1 do

                local attribute = attributes:child(i)
        
                if attribute:contains("Name", TYPE.STRING) then

                    local dbEntry = Database:find(context.edition, "attributes", attribute.lastFound.value)
                    
                    if(dbEntry.valid) then
                        Style:setLabel(attribute, dbEntry.name)
                        Style:setLabelColor(attribute, "#bfbfbf")
                    end
                end
            end
        elseif(context.edition == EDITION.CONSOLE) then
            for i=0, attributes.childCount-1 do

                local attribute = attributes:child(i)
        
                if attribute:contains("ID", TYPE.INT) then

                    local dbEntry = Database:find(context.edition, "attributes", tostring(attribute.lastFound.value))

                    if(dbEntry.valid) then
                        Style:setLabel(attribute, dbEntry.name)
                        Style:setLabelColor(attribute, "#bfbfbf")
                    end
                end
            end
        end
    end
end

-- ENTITY SPECIFIC

function EntityInfo.styler:RunEntitySpecifics(entity, context)

    local entityName = ""

    if((context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) and entity:contains("id", TYPE.STRING)) then

        local dbEntry = Database:find(context.edition, "entities", entity.lastFound.value)
        if(not dbEntry.valid) then return end

        entityName = dbEntry.name:gsub("[^%w]+", "")
    end

    if(context.edition == EDITION.BEDROCK) then

        local entityid = ""

        if(entity:contains("identifier", TYPE.STRING)) then entityid = entity.lastFound.value
        elseif(entity:contains("id", TYPE.STRING)) then entityid = entity.lastFound.value
        elseif(entity:contains("id", TYPE.INT)) then entityid = tostring(entity.lastFound.value & 255)
        else return end

        local dbEntry = Database:find(context.edition, "entities", entityid)
        if(not dbEntry.valid) then return end

        entityName = dbEntry.name:gsub("%s+", "")
    end

    if(self[entityName] == nil) then return end
    self[entityName](self, entity, context)
end

function EntityInfo.styler:Allay(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("DuplicationCooldown", TYPE.LONG)) then
            local cooldown = entity.lastFound

            if(cooldown.value > 0) then Style:setLabel(cooldown, "Duplicates in " .. self:ticksToTime(cooldown.value)) end
        end
        --if(entity:contains("listener", TYPE.COMPOUND)) then end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("AllayDuplicationCooldown", TYPE.LONG)) then
            local cooldown = entity.lastFound

            if(cooldown.value > 0) then Style:setLabel(cooldown, "Duplicates in " .. self:ticksToTime(cooldown.value)) end
        end
        --if(entity:contains("VibrationListener", TYPE.COMPOUND)) then end
    end
end

function EntityInfo.styler:Axolotl(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("Variant", TYPE.INT)) then

            local variantId = entity.lastFound
            local variant = ""
    
            if(variantId.value == 0) then variant = "Lucy"
            elseif(variantId.value == 1) then variant = "Wild"
            elseif(variantId.value == 2) then variant = "Gold"
            elseif(variantId.value == 3) then variant = "Cyan"
            elseif(variantId.value == 4) then variant = "Blue"
            end

            if(variantId.value >= 0 and variantId.value <= 4) then
                Style:setLabel(variantId, "Axolotl (" .. variant .. ")")
                Style:setLabel(entity, "Axolotl (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Axolotl" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Axolotl" .. variant .. ".png")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then

            local variantId = entity.lastFound
            local variant = ""
    
            if(variantId.value == 0) then variant = "Lucy"
            elseif(variantId.value == 1) then variant = "Cyan"
            elseif(variantId.value == 2) then variant = "Gold"
            elseif(variantId.value == 3) then variant = "Wild"
            elseif(variantId.value == 4) then variant = "Blue"
            end

            if(variantId.value >= 0 and variantId.value <= 4) then
                Style:setLabel(variantId, "Axolotl (" .. variant .. ")")
                Style:setLabel(entity, "Axolotl (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Axolotl" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Axolotl" .. variant .. ".png")
            end
        end

    end
end

function EntityInfo.styler:Bat(entity, context)

    if(entity:contains("BatFlags", TYPE.BYTE)) then

        local batFlags = entity.lastFound

        if(batFlags.value == 0) then Style:setLabel(batFlags, "Flying")
        elseif(batFlags.value == 1) then Style:setLabel(batFlags, "Hanging")
        end
    end
end

function EntityInfo.styler:Bee(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("FlowerPos", TYPE.COMPOUND)) then

            local flowerPos = entity.lastFound
            if(flowerPos.childCount == 3) then Style:setLabel(flowerPos, "X:" .. tostring(math.floor(flowerPos:child(0).value + 0.5)) .. ", Y:" .. tostring(math.floor(flowerPos:child(1).value + 0.5)) .. ", Z:" .. tostring(math.floor(flowerPos:child(2).value + 0.5))) end
            Style:setLabelColor(flowerPos, "#bfbfbf")

        end
    
        if(entity:contains("HivePos", TYPE.COMPOUND)) then
    
            local hivePos = entity.lastFound
            if(hivePos.childCount == 3) then Style:setLabel(hivePos, "X:" .. tostring(math.floor(hivePos:child(0).value + 0.5)) .. ", Y:" .. tostring(math.floor(hivePos:child(1).value + 0.5)) .. ", Z:" .. tostring(math.floor(hivePos:child(2).value + 0.5))) end
            Style:setLabelColor(hivePos, "#bfbfbf")
            
        end
    
        if(entity:contains("CannotEnterHiveTicks", TYPE.INT)) then
    
            local cannotEnterHiveTicks = entity.lastFound
    
            if(cannotEnterHiveTicks.value > 0) then
    
                Style:setLabel(cannotEnterHiveTicks, "Can enter hive in " .. self:ticksToTime(cannotEnterHiveTicks.value))
            end
        end
    
        if(entity:contains("TicksSincePollination", TYPE.INT)) then
    
            local lastPollination = entity.lastFound
    
            if(lastPollination.value > 0) then
    
                Style:setLabel(lastPollination, self:ticksToTime(lastPollination.value))
            end
        end
    end
end

function EntityInfo.styler:Cat(entity, context) 

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("variant", TYPE.STRING)) then

            local variantId = entity.lastFound
            local variant = ""
    
            if(variantId.value == "all_black") then variant = "Black"
            elseif(variantId.value == "black") then variant = "Tuxedo"
            elseif(variantId.value == "british_shorthair") then variant = "British Shorthair"
            elseif(variantId.value == "calico") then variant = "Calico"
            elseif(variantId.value == "jellie") then variant = "Jellie"
            elseif(variantId.value == "ocelot") then variant = "Ocelot"
            elseif(variantId.value == "persian") then variant = "Persian"
            elseif(variantId.value == "ragdoll") then variant = "Ragdoll"
            elseif(variantId.value == "red") then variant = "Red"
            elseif(variantId.value == "siamese") then variant = "Siamese"
            elseif(variantId.value == "tabby") then variant = "Tabby"
            elseif(variantId.value == "white") then variant = "White"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Cat (" .. variant .. ")")
                Style:setLabel(entity, "Cat (" .. variant .. ")")

                variant = string.gsub(variant, "%s+", "")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Cat" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Cat" .. variant .. ".png")
            end
        end
        
        if(entity:contains("CollarColor", TYPE.BYTE)) then 
        
            local collar = entity.lastFound

            if(collar.value >= 0 and collar.value < 16) then
                Style:setLabel(collar, self:colorToString(collar.value).name)
                Style:setLabelColor(collar, self:colorToString(collar.value).qtColor)
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then

            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == 9) then variant = "Black"
            elseif(variantId.value == 1) then variant = "Tuxedo"
            elseif(variantId.value == 4) then variant = "British Shorthair"
            elseif(variantId.value == 5) then variant = "Calico"
            elseif(variantId.value == 10) then variant = "Jellie"
            elseif(variantId.value == 6) then variant = "Persian"
            elseif(variantId.value == 7) then variant = "Ragdoll"
            elseif(variantId.value == 2) then variant = "Red"
            elseif(variantId.value == 3) then variant = "Siamese"
            elseif(variantId.value == 8) then variant = "Tabby"
            elseif(variantId.value == 0) then variant = "White"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Cat (" .. variant .. ")")
                Style:setLabel(entity, "Cat (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Cat" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Cat" .. variant .. ".png")
            end
        end

        if(entity:contains("Color", TYPE.BYTE)) then 
        
            local collar = entity.lastFound

            if(collar.value >= 0 and collar.value < 16) then
                Style:setLabel(collar, self:colorToString(collar.value).name .. " Collar")
                Style:setLabelColor(collar, self:colorToString(collar.value).qtColor)
            end
        end

    elseif(context.edition == EDITION.CONSOLE) then
    end
end

function EntityInfo.styler:Chicken(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("EggLayTime", TYPE.INT)) then
            
            local eggLayTime = entity.lastFound
            local ticks = eggLayTime.value

            Style:setLabel(eggLayTime, self:ticksToTime(ticks))
        end
    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("entries", TYPE.LIST, TYPE.COMPOUND)) then

            local entries = entity.lastFound

            for i=0, entries.childCount-1 do

                local entry = entries:child(i)

                if(entry:contains("SpawnTimer", TYPE.INT)) then 
                    
                    Style:setLabel(entry.lastFound, self:ticksToTime(entry.lastFound.value))
                    break
                end
            end
        end
    end

end

function EntityInfo.styler:Creeper(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("Fuse", TYPE.SHORT)) then 
        
            local fuse = entity.lastFound
            Style:setLabel(fuse, self:ticksToTime(fuse.value))
        end
        if(entity:contains("powered", TYPE.BYTE)) then 

            local powered = entity.lastFound

            if(powered.value == 1) then
                Style:setLabel(entity, "Charged Creeper")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/ChargedCreeper.png")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("definitions", TYPE.LIST, TYPE.STRING)) then

            local definitions = entity.lastFound 

            for i=0, definitions.childCount-1 do
                if(definitions:child(i).value == "+minecraft:charged_creeper") then 
                    Style:setLabel(entity, "Charged Creeper")
                    Style:setIcon(entity, "EntityInfo/images/entity_specific/ChargedCreeper.png")
                    break
                end
            end
        end
    end
end

function EntityInfo.styler:Dolphin(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("Moistness", TYPE.INT)) then
        
            local moist = entity.lastFound
            Style:setLabel(moist, self:ticksToTime(moist.value) .. " of moistness")
        end
    end
end

function EntityInfo.styler:EnderDragon(entity, context) -- UNVERIFIED (MISSING IN DATABASE)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("DragonPhase", TYPE.INT)) then
        
            local phase = entity.lastFound

            if(phase.value == 0) then Style:setLabel(phase, "Circling") end
            if(phase.value == 1) then Style:setLabel(phase, "Strafing") end
            if(phase.value == 2) then Style:setLabel(phase, "Flying") end
            if(phase.value == 3) then Style:setLabel(phase, "Landing on the portal") end
            if(phase.value == 4) then Style:setLabel(phase, "Leaving the portal") end
            if(phase.value == 5) then Style:setLabel(phase, "Landed & using breath attack") end
            if(phase.value == 6) then Style:setLabel(phase, "Landed & looking for breath attack target") end
            if(phase.value == 7) then Style:setLabel(phase, "Landed & roaring before breath attack") end
            if(phase.value == 8) then Style:setLabel(phase, "Charging a player") end
            if(phase.value == 9) then Style:setLabel(phase, "Flying to the portal to die") end
            if(phase.value == 10) then Style:setLabel(phase, "Hovering with no AI") end
        end
    end

end

function EntityInfo.styler:Endermite(entity, context)

    if(entity:contains("Lifetime", TYPE.INT)) then -- All platforms handle this the same <3

        local lifetime = entity.lastFound
        Style:setLabel(lifetime, self:ticksToTime(2400 - lifetime.value) .. " until death")
    end
end

function EntityInfo.styler:EvocationIllager(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("SpellTicks", TYPE.INT)) then 

            local spellTicks = entity.lastFound
            if(spellTicks.value == 0) then Style:setLabel(spellTicks, "Can cast a spell")
            elseif(spellTicks.value > 0) then Style:setLabel(spellTicks, "Can cast in " .. self:ticksToTime(spellTicks.value))
            end
        end
    end
end

function EntityInfo.styler:Fox(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("Type", TYPE.STRING)) then 
            
            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == "red") then variant = "Red"
            elseif(variantId.value == "snow") then variant = "Snow"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Fox (" .. variant .. ")")
                Style:setLabel(entity, "Fox (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Fox" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Fox" .. variant .. ".png")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then 
        
            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == 0) then variant = "Red"
            elseif(variantId.value == 1) then variant = "Snow"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Fox (" .. variant .. ")")
                Style:setLabel(entity, "Fox (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Fox" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Fox" .. variant .. ".png")
            end
        end
    end
end

function EntityInfo.styler:Frog(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("variant", TYPE.STRING)) then
        
            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == "minecraft:temperate") then variant = "Temperate"
            elseif(variantId.value == "minecraft:warm") then variant = "Warm"
            elseif(variantId.value == "minecraft:cold") then variant = "Cold"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Frog (" .. variant .. ")")
                Style:setLabel(entity, "Frog (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Frog" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Frog" .. variant .. ".png")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then
        
            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == 0) then variant = "Temperate"
            elseif(variantId.value == 1) then variant = "Cold"
            elseif(variantId.value == 2) then variant = "Warm"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Frog (" .. variant .. ")")
                Style:setLabel(entity, "Frog (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Frog" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Frog" .. variant .. ".png")
            end
        end
    end
end

function EntityInfo.styler:GlowSquid(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("DarkTicksRemaining")) then 
        
            local ticks = entity.lastFound

            if(ticks.value == 0) then Style:setLabel(ticks, "Glowing")
            elseif(ticks.value > 0) then Style:setLabel(ticks, "Glowing in " .. self:ticksToTime(ticks.value))
            end
        end
    end
end

function EntityInfo.styler:Hoglin(entity, context)

    if(context.edition == EDITION.JAVA) then
        if(entity:contains("TimeInOverworld", TYPE.INT) and entity.lastFound.value > 0) then Style:setLabel(ticks, "Converts to a Zoglin in " .. self:ticksToTime(300 - entity.lastFound.value)) end
    end
end

function EntityInfo.styler:Horse(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("Variant", TYPE.INT)) then 
        
            local variant = entity.lastFound
            local color = ""
            local pattern = ""
            local icon = ""

            local colorId = (variant.value & 0xff) %7

            if(colorId == 0) then color = "White"
            elseif(colorId == 1) then color = "Creamy"
            elseif(colorId == 2) then color = "Chestnut"
            elseif(colorId == 3) then color = "Brown"
            elseif(colorId == 4) then color = "Black"
            elseif(colorId == 5) then color = "Gray"
            elseif(colorId == 6) then color = "Dark Brown"
            end

            local patternId = ((variant.value >> 8) & 0xff) %5

            if(patternId == 0) then pattern = "Plain"
            elseif(patternId == 1) then pattern = "White"
            elseif(patternId == 2) then pattern = "White Field"
            elseif(patternId == 3) then pattern = "White Dots"
            elseif(patternId == 4) then pattern = "Black Dots"
            end

            icon = "Horse" .. string.gsub(color, "%s+", "")

            Style:setLabel(variant, color .. " & " .. pattern)
            Style:setLabel(entity, "Horse (" .. color .. ")")

            Style:setIcon(variant, "EntityInfo/images/entity_specific/" .. icon .. ".png")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/" .. icon .. ".png")

            
        end
    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then 
        
            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == 0) then variant = "White"
            elseif(variantId.value == 1) then variant = "Creamy"
            elseif(variantId.value == 2) then variant = "Chestnut"
            elseif(variantId.value == 3) then variant = "Brown"
            elseif(variantId.value == 4) then variant = "Black"
            elseif(variantId.value == 5) then variant = "Gray"
            elseif(variantId.value == 6) then variant = "Dark Brown"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, "Horse (" .. variant .. ")")
                Style:setLabel(entity, "Horse (" .. variant .. ")")

                icon = "Horse" .. string.gsub(variant, "%s+", "")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/" .. icon .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/" .. icon .. ".png")
            end
        end

        if(entity:contains("MarkVariant", TYPE.INT)) then

            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == 0) then variant = "No Markings"
            elseif(variantId.value == 1) then variant = "White Details"
            elseif(variantId.value == 2) then variant = "White Fields"
            elseif(variantId.value == 3) then variant = "White Dots"
            elseif(variantId.value == 4) then variant = "Black Dots"
            end

            if(variant ~= "") then
                Style:setLabel(variantId, variant)
                Style:setLabel(entity, variant)
            end

        end

    elseif(context.edition == EDITION.CONSOLE) then

        local isHorse = true

        if(entity:contains("Type", TYPE.INT)) then

            local typeNum = entity.lastFound
            local typeStr = ""
            local icon = ""

            if(typeNum.value == 1) then typeStr = "Donkey"
            elseif(typeNum.value == 2) then typeStr = "Mule"
            elseif(typeNum.value == 3) then typeStr = "Zombie Horse"
            elseif(typeNum.value == 4) then typeStr = "Skeleton Horse"
            end
            
            isHorse = typeNum.value == 0

            icon = string.gsub(typeStr, "%s+", "")

            if(icon ~= "") then 
                Style:setLabel(entity, typeStr)
                Style:setIcon(entity, "EntityInfo/images/entities/" .. icon .. ".png")
                Style:setLabel(typeNum, typeStr)
                Style:setIcon(typeNum, "EntityInfo/images/entities/" .. icon .. ".png")
            end
        end

        if(isHorse and entity:contains("Variant", TYPE.INT)) then 
        
            local variant = entity.lastFound
            local color = ""
            local pattern = ""
            local icon = ""

            local colorId = (variant.value & 0xff) %7

            if(colorId == 0) then color = "White"
            elseif(colorId == 1) then color = "Creamy"
            elseif(colorId == 2) then color = "Chestnut"
            elseif(colorId == 3) then color = "Brown"
            elseif(colorId == 4) then color = "Black"
            elseif(colorId == 5) then color = "Gray"
            elseif(colorId == 6) then color = "Dark Brown"
            end

            local patternId = ((variant.value >> 8) & 0xff) %5

            if(patternId == 0) then pattern = "Plain"
            elseif(patternId == 1) then pattern = "White"
            elseif(patternId == 2) then pattern = "White Field"
            elseif(patternId == 3) then pattern = "White Dots"
            elseif(patternId == 4) then pattern = "Black Dots"
            end

            icon = "Horse" .. string.gsub(color, "%s+", "")

            Style:setLabel(variant, color .. " & " .. pattern)
            Style:setLabel(entity, "Horse (" .. color .. ")")

            Style:setIcon(variant, "EntityInfo/images/entity_specific/" .. icon .. ".png")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/" .. icon .. ".png")
        end
    end
end

function EntityInfo.styler:Illusioner(entity, context) -- UNVERIFIED (MISSING IN DATABASE)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("SpellTicks", TYPE.INT)) then 

            local spellTicks = entity.lastFound
            if(spellTicks.value == 0) then Style:setLabel(spellTicks, "Can cast a spell")
            elseif(spellTicks.value > 0) then Style:setLabel(spellTicks, "Can cast in " .. self:ticksToTime(spellTicks.value))
            end
        end
    end
end

function EntityInfo.styler:Llama(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.BEDROCK) then

        if(entity:contains("Strength", TYPE.INT)) then 
        
            local str = entity.lastFound
            if(str.value >= 1 and str.value <= 5) then Style:setLabel(str, str.value*3 .. " inventory slots") end
        
        end

        if(entity:contains("Variant", TYPE.INT)) then

            local variantId = entity.lastFound
            local variant = ""

            if(variantId.value == 0) then variant = "Creamy"
            elseif(variantId.value == 1) then variant = "White"
            elseif(variantId.value == 2) then variant = "Brown"
            elseif(variantId.value == 3) then variant = "Gray"
            end

            if(variantId.value >= 0 and variantId.value <= 3) then
                Style:setLabel(variantId, "Llama (" .. variant .. ")")
                Style:setLabel(entity, "Llama (" .. variant .. ")")

                Style:setIcon(variantId, "EntityInfo/images/entity_specific/Llama" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Llama" .. variant .. ".png")
            end
        end
    end
end

function EntityInfo.styler:TraderLlama(entity, context) -- UNVERIFIED (MISSING IN DATABASE)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("DespawnDelay", TYPE.INT)) then

            local despawn = entity.lastFound
            Style:setLabel(despawn, "Despawns in " .. ticksToTime(despawn.value))

        end
        
    elseif(context.edition == EDITION.BEDROCK) then
    elseif(context.edition == EDITION.CONSOLE) then
    end
end

function EntityInfo.styler:MagmaCube(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("Size", TYPE.INT)) then
        
            local Size = entity.lastFound
            local sizeStr =""
        
            if(Size.value == 0) then sizeStr = "Small"
            elseif(Size.value == 1) then sizeStr = "Medium"
            elseif(Size.value == 3) then sizeStr = "Large"
            end

            if(Size.value == 0 or Size.value == 1 or Size.value == 3) then
                Style:setLabel(entity, "Slime (" .. sizeStr .. ")")
                Style:setLabel(Size, sizeStr)
            end
        end
    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("definitions", TYPE.LIST, TYPE.STRING)) then 
        
            local definitions = entity.lastFound
            local size = ""

            for i=0, definitions.childCount-1 do
    
                local definition = definitions:child(i).value
                
                if(definition == "+minecraft:slime_small") then size = "Small" break
                elseif(definition == "+minecraft:slime_medium") then size = "Medium" break
                elseif(definition == "+minecraft:slime_large") then size = "Large" break
                end

            end

            if(size ~= "") then Style:setLabel(entity, "Magma Cube (" .. size .. ")") end
        end

    elseif(context.edition == EDITION.CONSOLE) then

        if(entity:contains("Size", TYPE.INT)) then
        
            local Size = entity.lastFound
            local sizeStr =""
        
            if(Size.value == 0) then sizeStr = "Small"
            elseif(Size.value == 1) then sizeStr = "Medium"
            elseif(Size.value == 2) then sizeStr = "Large"
            end

            if(Size.value == 0 or Size.value == 1 or Size.value == 3) then
                Style:setLabel(entity, "Slime (" .. sizeStr .. ")")
                Style:setLabel(Size, sizeStr)
            end
        end
    end
end

function EntityInfo.styler:Mooshroom(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("EffectId", TYPE.INT)) then 
        
            local effectId = entity.lastFound

            local dbEntry = Database:find(context.edition, "active_effects", tostring(effectId.value))

            if(dbEntry.valid) then

                local effectName = dbEntry.name

                Style:setLabel(effectId, effectName)

                effectName = effectName:gsub("[^%w]+", "")

                Style:setIcon(effectId, "EntityInfo/images/effects/" .. effectName .. ".png")
            end

        end

        if(entity:contains("EffectDuration", TYPE.INT)) then 
        
            local duration = entity.lastFound
            Style:setLabel(duration, (self:ticksToTime(duration.value)))

        end

        if(entity:contains("Type", TYPE.STRING)) then 
        
            local variant = entity.lastFound
            local varStr = ""

            if(variant.value == "red") then varStr = "Red"
            elseif(variant.value == "brown") then varStr = "Brown"
            end

            if(varStr == "Red"  or varStr == "Brown") then
                Style:setLabel(entity, "Mooshroom (" .. varStr .. ")")
                Style:setLabel(variant, varStr)

                Style:setIcon(entity, "EntityInfo/images/entity_specific/Mooshroom" .. varStr .. ".png")
                Style:setIcon(variant, "EntityInfo/images/entity_specific/Mooshroom" .. varStr .. ".png")
            end

        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then 
        
            local variant = entity.lastFound
            local varStr = ""

            if(variant.value == 0) then varStr = "Red"
            elseif(variant.value == 1) then varStr = "Brown"
            end

            if(varStr == "Red"  or varStr == "Brown") then
                Style:setLabel(entity, "Mooshroom (" .. varStr .. ")")
                Style:setLabel(variant, varStr)

                Style:setIcon(entity, "EntityInfo/images/entity_specific/Mooshroom" .. varStr .. ".png")
                Style:setIcon(variant, "EntityInfo/images/entity_specific/Mooshroom" .. varStr .. ".png")
            end

        end

        if(entity:contains("MarkVariant", TYPE.INT)) then 
        
            local brokenEffectId = entity.lastFound
            local effectId = -1

            if(brokenEffectId.value == 0) then effectId = 16
            elseif(brokenEffectId.value == 1) then effectId = 8
            elseif(brokenEffectId.value == 2) then effectId = 18
            elseif(brokenEffectId.value == 3) then effectId = 15
            elseif(brokenEffectId.value == 4) then effectId = 19
            elseif(brokenEffectId.value == 7) then effectId = 12
            elseif(brokenEffectId.value == 8) then effectId = 10
            elseif(brokenEffectId.value == 9) then effectId = 20
            end

            local dbEntry = Database:find(context.edition, "active_effects", tostring(effectId))

            if(dbEntry.valid) then

                local effectName = dbEntry.name

                Style:setLabel(brokenEffectId, effectName)

                effectName = effectName:gsub("[^%w]+", "")

                Style:setIcon(brokenEffectId, "EntityInfo/images/effects/" .. effectName .. ".png")
            end
        end
    end
end

function EntityInfo.styler:Panda(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("MainGene", TYPE.STRING) and entity:contains("HiddenGene", TYPE.STRING)) then

            local mainGene = nil
            local hiddenGene = nil

            function formatGenes(geneId)

                if(geneId == "normal") then return "Normal"
                elseif(geneId == "aggressive") then return "Aggressive"
                elseif(geneId == "brown") then return "Brown"
                elseif(geneId == "lazy") then return "Lazy"
                elseif(geneId == "playful") then return "Playful"
                elseif(geneId == "weak") then return "Weak"
                elseif(geneId == "worried") then return "Worried"
                end

                return "Normal"
            end

            if(entity:contains("MainGene", TYPE.STRING)) then
                mainGene = entity.lastFound
                mainGene.formattedName = formatGenes(mainGene.value)
                Style:setIcon(mainGene, "EntityInfo/images/entity_specific/Panda" .. mainGene.formattedName .. ".png")
            end
            if(entity:contains("HiddenGene", TYPE.STRING)) then
                hiddenGene = entity.lastFound
                hiddenGene.formattedName = formatGenes(hiddenGene.value)
                Style:setIcon(hiddenGene, "EntityInfo/images/entity_specific/Panda" .. hiddenGene.formattedName .. ".png")
            end
            if((mainGene.formattedName == "Normal" or mainGene.formattedName == "Aggressive" or mainGene.formattedName == "Lazy" or mainGene.formattedName == "Worried" or mainGene.formattedName == "Playful") or (hiddenGene.formattedName == mainGene.formattedName)) then
                Style:setLabel(entity, mainGene.formattedName)
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Panda" .. mainGene.formattedName .. ".png")
            else
                Style:setLabel(entity, "Normal")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/PandaNormal.png")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("GeneArray", TYPE.LIST, TYPE.COMPOUND)) then
            local genes = entity.lastFound:child(0)

            function formatGenes(gene)
                if(gene == 0) then return "Lazy"
                elseif(gene == 1) then return "Worried"
                elseif(gene == 2) then return "Playful"
                elseif(gene == 3) then return "Aggressive"
                elseif(gene == 4) then return "Weak"
                elseif(gene == 5) then return "Weak"
                elseif(gene == 6) then return "Weak"
                elseif(gene == 7) then return "Weak"
                elseif(gene == 8) then return "Brown"
                elseif(gene == 9) then return "Brown"
                elseif(gene == 10) then return "Normal"
                elseif(gene == 11) then return "Normal"
                elseif(gene == 12) then return "Normal"
                elseif(gene == 13) then return "Normal"
                elseif(gene == 14) then return "Normal"
                end

                return "Normal"
            end

            if(genes:contains("HiddenAllele", TYPE.INT)) then
                local gene = genes.lastFound
                gene.formattedName = formatGenes(gene.value)
                Style:setLabel(gene, gene.formattedName)
                Style:setIcon(gene, "EntityInfo/images/entity_specific/Panda" .. gene.formattedName .. ".png")
            end
            if(genes:contains("MainAllele", TYPE.INT)) then
                local gene = genes.lastFound
                gene.formattedName = formatGenes(gene.value)
                Style:setLabel(gene, gene.formattedName)
                Style:setIcon(gene, "EntityInfo/images/entity_specific/Panda" .. gene.formattedName .. ".png")
            end
        end

        if(entity:contains("Variant", TYPE.INT)) then
            local gene = entity.lastFound

            if(gene.value == 0) then gene.formattedName = "Normal"
            elseif(gene.value == 1) then gene.formattedName = "Lazy"
            elseif(gene.value == 2) then gene.formattedName = "Worried"
            elseif(gene.value == 3) then gene.formattedName = "Playful"
            elseif(gene.value == 4) then gene.formattedName = "Brown"
            elseif(gene.value == 5) then gene.formattedName = "Weak"
            elseif(gene.value == 6) then gene.formattedName = "Aggressive"
            end

            Style:setLabel(gene, gene.formattedName)
            Style:setIcon(gene, "EntityInfo/images/entity_specific/Panda" .. gene.formattedName .. ".png")
            Style:setLabel(entity, gene.formattedName)
            Style:setIcon(entity, "EntityInfo/images/entity_specific/Panda" .. gene.formattedName .. ".png")
        end
    end
end

function EntityInfo.styler:Parrot(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.BEDROCK or context.edition == EDITION.CONSOLE) then

        if(entity:contains("Variant", TYPE.INT)) then
            local variantTag = entity.lastFound
            local variant = ""

            if(variantTag.value == 0) then variant = "Red"
            elseif(variantTag.value == 1) then variant = "Blue"
            elseif(variantTag.value == 2) then variant = "Green"
            elseif(variantTag.value == 3) then variant = "Cyan"
            elseif(variantTag.value == 4) then variant = "Gray"
            end
        
            if(variant ~= "") then
                Style:setLabel(variantTag, "Parrot (" .. variant .. ")")
                Style:setLabel(entity, "Parrot (" .. variant .. ")")

                Style:setIcon(variantTag, "EntityInfo/images/entity_specific/Parrot" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Parrot" .. variant .. ".png")
            end
        end
    elseif(context.edition == EDITION.CONSOLE) then
    end
end

function EntityInfo.styler:Phantom(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then
        local x, y, z = nil

        if(entity:contains("AX", TYPE.INT)) then x = entity.lastFound.value end
        if(entity:contains("AY", TYPE.INT)) then y = entity.lastFound.value end
        if(entity:contains("AZ", TYPE.INT)) then z = entity.lastFound.value end

        if(x ~= nil and y ~= nil and z ~= nil) then Style:setLabel(entity, "Phantom (Circling:" .. " Z:" .. x .. ", Z:" .. y .. ", Z:" .. z .. ")") end
        if(entity:contains("Size", TYPE.INT)) then Style:setLabel(entity.lastFound, "Deals " .. string.gsub(string.format("%.1f", (entity.lastFound.value+6)/2), "%.0", "") .. " hearts of damage") end
    end
end

function EntityInfo.styler:Piglin(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("TimeInOverworld", TYPE.INT) and entity.lastFound.value > 0) then Style:setLabel(ticks, "Converts to a Zombified Piglin in " .. self:ticksToTime(300 - entity.lastFound.value)) end
        if(entity:contains("IsBaby", TYPE.BYTE) and entity.lastFound.value == 1) then Style:setLabel(entity, "Piglin (Baby)") end

    end
end

function EntityInfo.styler:PiglinBrute(entity, context) -- UNVERIFIED (MISSING IN DATABASE)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("TimeInOverworld", TYPE.INT) and entity.lastFound.value > 0) then Style:setLabel(ticks, "Converts to a Zombified Piglin in " .. self:ticksToTime(300 - entity.lastFound.value)) end
        
    end
end

function EntityInfo.styler:Pufferfish(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("PuffState", TYPE.INT)) then
            local id = entity.lastFound.value
            local puffState = ""

            if(id == 0) then puffState = "Deflated"
            elseif(id == 1) then puffState = "Half puffed-up"
            elseif(id == 2) then puffState = "Puffed-up"
            end

            Style:setLabel(entity.lastFound, puffState)
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then
            local id = entity.lastFound.value
            local puffState = ""

            if(id == 0) then puffState = "Deflated"
            elseif(id == 1) then puffState = "Half puffed-up"
            elseif(id == 2) then puffState = "Puffed-up"
            end

            Style:setLabel(entity.lastFound, puffState)
        end
    end
end

function EntityInfo.styler:Rabbit(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(self:getCustomNameJava(entity) == "Toast") then
            Style:setLabel(entity, "Rabbit (Toast)")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/RabbitToast.png")
        elseif(entity:contains("RabbitType", TYPE.INT)) then
            local rabbitType = entity.lastFound
            local variant = ""

            if(rabbitType.value == 0) then variant = "Brown"
            elseif(rabbitType.value == 1) then variant = "White"
            elseif(rabbitType.value == 2) then variant = "Black"
            elseif(rabbitType.value == 3) then variant = "Black and White"
            elseif(rabbitType.value == 4) then variant = "Gold"
            elseif(rabbitType.value == 5) then variant = "Salt and Pepper"
            elseif(rabbitType.value == 99) then variant = "The Killer Bunny"
            end

            if(variant ~= "") then
                Style:setLabel(rabbitType, "Rabbit (" .. variant .. ")")
                Style:setLabel(entity, "Rabbit (" .. variant .. ")")
    
                variant = string.gsub(variant, "%s+", "")

                Style:setIcon(rabbitType, "EntityInfo/images/entity_specific/Rabbit" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Rabbit" .. variant .. ".png")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("CustomName", TYPE.STRING) and entity.lastFound.value == "Toast") then
            Style:setLabel(entity, "Rabbit (Toast)")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/RabbitToast.png")
        elseif(entity:contains("Variant", TYPE.INT)) then
            local rabbitType = entity.lastFound
            local variant = ""

            if(rabbitType.value == 0) then variant = "Brown"
            elseif(rabbitType.value == 1) then variant = "White"
            elseif(rabbitType.value == 2) then variant = "Black"
            elseif(rabbitType.value == 3) then variant = "Black and White"
            elseif(rabbitType.value == 4) then variant = "Gold"
            elseif(rabbitType.value == 5) then variant = "Salt and Pepper"
            end

            if(variant ~= "") then
                Style:setLabel(rabbitType, "Rabbit (" .. variant .. ")")
                Style:setLabel(entity, "Rabbit (" .. variant .. ")")
    
                variant = string.gsub(variant, "%s+", "")

                Style:setIcon(rabbitType, "EntityInfo/images/entity_specific/Rabbit" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Rabbit" .. variant .. ".png")
            end
        end

    elseif(context.edition == EDITION.CONSOLE) then

        if(entity:contains("CustomName", TYPE.STRING) and entity.lastFound.value == "Toast") then
            Style:setLabel(entity, "Rabbit (Toast)")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/RabbitToast.png")
        elseif(entity:contains("RabbitType", TYPE.INT)) then
            local rabbitType = entity.lastFound
            local variant = ""

            if(rabbitType.value == 0) then variant = "Brown"
            elseif(rabbitType.value == 1) then variant = "White"
            elseif(rabbitType.value == 2) then variant = "Black"
            elseif(rabbitType.value == 3) then variant = "Black and White"
            elseif(rabbitType.value == 4) then variant = "Gold"
            elseif(rabbitType.value == 5) then variant = "Salt and Pepper"
            elseif(rabbitType.value == 99) then variant = "The Killer Bunny"
            end

            if(variant ~= "") then
                Style:setLabel(rabbitType, "Rabbit (" .. variant .. ")")
                Style:setLabel(entity, "Rabbit (" .. variant .. ")")
    
                variant = string.gsub(variant, "%s+", "")

                Style:setIcon(rabbitType, "EntityInfo/images/entity_specific/Rabbit" .. variant .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Rabbit" .. variant .. ".png")
            end
        end

    end
end

function EntityInfo.styler:Ravager(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("AttackTick", TYPE.INT)) then
            if(entity.lastFound.value > 0) then Style:setLabel(entity.lastFound, self:ticksToTime(entity.lastFound.value) .. " attack cooldown") end
        end
        if(entity:contains("RoarTick", TYPE.INT)) then
            if(entity.lastFound.value > 0) then Style:setLabel(entity.lastFound, self:ticksToTime(entity.lastFound.value) .. " roar cooldown") end
        end
        if(entity:contains("StunTick", TYPE.INT)) then
            if(entity.lastFound.value > 0) then Style:setLabel(entity.lastFound, self:ticksToTime(entity.lastFound.value) .. " stun cooldown") end
        end
    end
end

function EntityInfo.styler:Sheep(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.BEDROCK or context.edition == EDITION.CONSOLE) then

        if(entity:contains("Color", TYPE.BYTE)) then
            local colorId = entity.lastFound.value

            if(colorId >= 0 and colorId < 16) then
                local colorStr = self:colorToString(colorId).name

                Style:setLabel(entity.lastFound, "Sheep (" .. colorStr .. ")")
                Style:setLabel(entity, "Sheep (" .. colorStr .. ")")
    
                colorStr = string.gsub(colorStr, "%s+", "")

                Style:setIcon(entity.lastFound, "EntityInfo/images/entity_specific/Sheep" .. colorStr .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Sheep" .. colorStr .. ".png")
            end
        end
    end
end

function EntityInfo.styler:Shulker(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("Color", TYPE.BYTE)) then
            local colorId = entity.lastFound.value
            
            if(colorId >= 0 and colorId < 16) then
                local colorStr = self:colorToString(colorId).name

                Style:setLabel(entity.lastFound, "Shulker (" .. colorStr .. ")")
                Style:setLabel(entity, "Shulker (" .. colorStr .. ")")
    
                colorStr = string.gsub(colorStr, "%s+", "")

                Style:setIcon(entity.lastFound, "EntityInfo/images/entity_specific/Shulker" .. colorStr .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Shulker" .. colorStr .. ".png")
            end
        end

        if(entity:contains("AttachFace", TYPE.BYTE)) then
            local face = entity.lastFound.value
            local faceStr = ""

            if(face == 0) then faceStr = "Up"
            elseif(face == 1) then faceStr = "Down"
            elseif(face == 2) then faceStr = "South"
            elseif(face == 3) then faceStr = "North"
            elseif(face == 4) then faceStr = "East"
            elseif(face == 5) then faceStr = "West"
            end

            if(faceStr ~= "") then
                Style:setLabel(entity.lastFound, "Opens " .. faceStr)
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Variant", TYPE.INT)) then
            local colorId = entity.lastFound.value
            
            if(colorId >= 0 and colorId < 16) then
                local colorStr = self:colorToString(15 - colorId).name

                Style:setLabel(entity.lastFound, "Shulker (" .. colorStr .. ")")
                Style:setLabel(entity, "Shulker (" .. colorStr .. ")")
    
                colorStr = string.gsub(colorStr, "%s+", "")

                Style:setIcon(entity.lastFound, "EntityInfo/images/entity_specific/Shulker" .. colorStr .. ".png")
                Style:setIcon(entity, "EntityInfo/images/entity_specific/Shulker" .. colorStr .. ".png")
            end
        end

    end
end

function EntityInfo.styler:Skeleton(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("StrayConversionTime", TYPE.INT)) then
            local convTicks = entity.lastFound.value
            
            if(convTicks > 0 and convTicks <= 300) then
                Style:setLabel(entity.lastFound, "Converts to a Stray in " .. self:ticksToTime(convTicks))
            end
        end
    end
end

function EntityInfo.styler:SkeletonHorse(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("SkeletonTrap", TYPE.BYTE) and entity.lastFound.value == 1) then
            Style:setLabel(entity, "Skeleton Horse (Trap)")

            if(entity:contains("SkeletonTrapTime", TYPE.INT)) then
                local despawnTicks = entity.lastFound.value

                if(despawnTicks >= 0 and despawnTicks < 18000) then
                    Style:setLabel(entity.lastFound, "Despawns in " .. self:ticksToTime(18000 - despawnTicks))
                end
            end
        end
    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("definitions", TYPE.LIST, TYPE.STRING)) then
            local definitions = entity.lastFound 

            for i=0, definitions.childCount-1 do
                if(definitions:child(i).value == "+minecraft:skeleton_trap") then 
                    Style:setLabel(entity, "Skeleton Horse (Trap)")
                    break
                end
            end
        end
    end
end

function EntityInfo.styler:Slime(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then

        if(entity:contains("Size", TYPE.INT)) then
            local size = entity.lastFound.value
            local sizeStr = ""

            if(size == 0) then sizeStr = "Small"
            elseif(size == 1) then sizeStr = "Medium"
            elseif(size == 3) then sizeStr = "Large"
            end

            if(sizeStr ~= "") then
                Style:setLabel(entity.lastFound, sizeStr)
                Style:setLabel(entity, "Slime (" .. sizeStr .. ")")
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Size", TYPE.BYTE)) then
            local size = entity.lastFound.value
            local sizeStr = ""

            if(size == 1) then sizeStr = "Small"
            elseif(size == 2) then sizeStr = "Medium"
            elseif(size == 4) then sizeStr = "Large"
            end

            if(sizeStr ~= "") then
                Style:setLabel(entity.lastFound, sizeStr)
                Style:setLabel(entity, "Slime (" .. sizeStr .. ")")
            end
        end
    end
end

function EntityInfo.styler:Tadpole(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("Age", TYPE.INT)) then
            local ageTicks = entity.lastFound.value
            
            if(ageTicks >= 0 and ageTicks < 24000) then Style:setLabel(entity.lastFound, "Grows into a Frog in " .. self:ticksToTime(24000 - ageTicks)) end
        end
    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Age", TYPE.INT)) then
            local ageTicks = entity.lastFound.value
            
            if(ageTicks >= -24000 and ageTicks < 0) then Style:setLabel(entity.lastFound, "Grows into a Frog in " .. self:ticksToTime(math.abs(ageTicks))) end
        end
    end
end

function EntityInfo.styler:TropicalFish(entity, context) -- missing console

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("Variant", TYPE.INT)) then
            local variant = entity.lastFound

            local sizeId = (variant.value & 0xff) %2
            local size = ""

            if(sizeId == 0) then size = "Small"
            elseif(sizeId == 1) then size = "Big"
            end

            local patternId = ((variant.value >> 8) & 0xff) %6
            local pattern = ""

            if(patternId == 0) then pattern = "Flopper"
            elseif(patternId == 1) then pattern = "Stripey"
            elseif(patternId == 2) then pattern = "Glitter"
            elseif(patternId == 3) then pattern = "Blockfish"
            elseif(patternId == 4) then pattern = "Betty"
            elseif(patternId == 5) then pattern = "Clayfish"
            end

            local baseColorId = ((variant.value >> 16) & 0xff) %16
            local baseColor = self:colorToString(baseColorId).name

            local patternColorId = ((variant.value >> 24) & 0xff) %16
            local patternColor = self:colorToString(patternColorId).name

            Style:setLabel(entity, "Tropical Fish (" .. size .. " " .. baseColor .. "-" .. patternColor .. " " .. pattern .. ")")
        end

    elseif(context.edition == EDITION.BEDROCK) then

        local baseColor = ""
        local patternColor = ""
        local size = ""
        local pattern = ""

        if(entity:contains("Color", TYPE.BYTE)) then
            local baseColorId = entity.lastFound.value

            if(baseColorId >= 0 and baseColorId < 16) then
                baseColor = self:colorToString(baseColorId).name

                Style:setLabel(entity.lastFound, baseColor)
                Style:setLabelColor(entity.lastFound, self:colorToString(baseColorId).qtColor)
            end
        end
        if(entity:contains("Color2", TYPE.BYTE)) then
            local patternColorId = entity.lastFound.value

            if(patternColorId >= 0 and patternColorId < 16) then
                patternColor = self:colorToString(patternColorId).name
                Style:setLabel(entity.lastFound, patternColor)
                Style:setLabelColor(entity.lastFound, self:colorToString(patternColorId).qtColor)
            end
        end
        if(entity:contains("Variant", TYPE.INT)) then
            local sizeId = entity.lastFound.value

            if(sizeId == 0) then size = "Small"
            elseif(sizeId == 1) then size = "Big"
            end

            if(size ~= "") then
                Style:setLabel(entity.lastFound, size)
            end
        end
        if(entity:contains("MarkVariant", TYPE.INT)) then
            local patternId = entity.lastFound.value


            if(patternId == 0) then pattern = "Flopper"
            elseif(patternId == 1) then pattern = "Stripey"
            elseif(patternId == 2) then pattern = "Glitter"
            elseif(patternId == 3) then pattern = "Blockfish"
            elseif(patternId == 4) then pattern = "Betty"
            elseif(patternId == 5) then pattern = "Clayfish"
            end

            if(pattern ~= "") then
                Style:setLabel(entity.lastFound, pattern)
            end
        end

        if(size ~= "" and baseColor ~= "" and patternColor ~= "" and pattern ~= "") then
            Print(baseColor, patternColor, size, pattern)
            Style:setLabel(entity, "Tropical Fish (" .. size .. " " .. baseColor .. "-" .. patternColor .. " " .. pattern .. ")")
        end

    elseif(context.edition == EDITION.CONSOLE) then
    end
end

function EntityInfo.styler:Wither(entity, context)

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then 
        
        if(entity:contains("Invul", TYPE.INT)) then -- Bedcock handles this weirdly. Decided not to touch it.
            local invulTicks = entity.lastFound.value
        
            if(invulTicks > 0) then
                Style:setLabel(entity.lastFound, "Invulnerable for " .. self:ticksToTime(entity.lastFound.value))
            end
        end

    end
end

function EntityInfo.styler:Wolf(entity, context) 

    if(context.edition == EDITION.JAVA or context.edition == EDITION.CONSOLE) then
        
        if(entity:contains("CollarColor", TYPE.BYTE)) then 
            local collar = entity.lastFound

            if(collar.value >= 0 and collar.value < 16) then
                Style:setLabel(collar, self:colorToString(collar.value).name)
                Style:setLabelColor(collar, self:colorToString(collar.value).qtColor)
            end
        end

    elseif(context.edition == EDITION.BEDROCK) then

        if(entity:contains("Color", TYPE.BYTE)) then
            local collar = entity.lastFound

            if(collar.value >= 0 and collar.value < 16) then
                Style:setLabel(collar, self:colorToString(collar.value).name .. " Collar")
                Style:setLabelColor(collar, self:colorToString(collar.value).qtColor)
            end
        end

    end
end

function EntityInfo.styler:Zoglin(entity, context)

    if(context.edition == EDITION.JAVA) then

        if(entity:contains("IsBaby", TYPE.BYTE)) then 
            if(entity.lastFound.value == 1) then Style:setLabel(entity, "Zoglin (Baby)") end
        end

    elseif(context.edition == EDITION.BEDROCK) then
        local isBaby = false
        local babyDefinition = false

        if(entity:contains("IsBaby", TYPE.BYTE)) then 
            if(entity.lastFound.value == 1) then isBaby = 1 end
        end
        if(entity:contains("definitions", TYPE.LIST, TYPE.STRING)) then
            local definitions = entity.lastFound 

            for i=0, definitions.childCount-1 do
                if(definitions:child(i).value == "+zoglin_baby") then
                    babyDefinition = 1
                    break
                end
            end
        end

        if(isBaby and babyDefinition) then Style:setLabel(entity, "Zoglin (Baby)") end

    elseif(context.edition == EDITION.CONSOLE) then
    end
end

function EntityInfo.styler:Villager(entity, context)

    if(context.edition == EDITION.JAVA) then
        local id = ""
        local meta = ""
        local vType = ""

        if(context.version < 1901) then
            if(entity:contains("Career", TYPE.INT)) then meta = tostring(entity.lastFound.value) else meta = "1" end
            if(entity:contains("Profession", TYPE.INT)) then id = tostring(entity.lastFound.value) end
        else
            if(entity:contains("VillagerData", TYPE.COMPOUND)) then
                local vData = entity.lastFound
                if(vData:contains("profession", TYPE.STRING)) then id = vData.lastFound.value end
                if(vData:contains("type", TYPE.STRING)) then
                    vType = vData.lastFound.value

                    if(vType:find("^minecraft:")) then vType = vType:sub(11) end

                    if(vType == "plains") then vType = "Plains "
                    elseif(vType == "desert") then vType = "Desert "
                    elseif(vType == "jungle") then vType = "Jungle "
                    elseif(vType == "savanna") then vType = "Savanna "
                    elseif(vType == "snow") then vType = "Snow "
                    elseif(vType == "swamp") then vType = "Swamp "
                    elseif(vType == "taiga") then vType = "Taiga "
                    else vType = ""
                    end
                end
            end
        end

        local jobEntry = Database:find(context.edition, "villager_professions", id, meta, context.version, -1)

        if(jobEntry ~= nil and jobEntry.valid) then
            Style:setLabel(entity, "Villager (" .. vType .. jobEntry.name .. ")")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/Villager" .. jobEntry.name .. ".png")
        elseif(vType ~= "") then
            Style:setLabel(entity, "Villager (" .. vType:sub(1, -2) .. ")")
        end

        -- Villager (Desert Cleric)

    elseif(context.edition == EDITION.BEDROCK) then
        local id = ""
        local vType = ""

        if(entity:contains("MarkVariant", TYPE.INT)) then
            vType = entity.lastFound.value

            if(vType == 0) then vType = "Plains "
            elseif(vType == 1) then vType = "Desert "
            elseif(vType == 2) then vType = "Jungle "
            elseif(vType == 3) then vType = "Savanna "
            elseif(vType == 4) then vType = "Snow "
            elseif(vType == 5) then vType = "Swamp "
            elseif(vType == 6) then vType = "Taiga "
            else vType = ""
            end
        end
        if(entity:contains("Variant", TYPE.INT)) then id = tostring(entity.lastFound.value)
        elseif(entity:contains("PreferredProfession", TYPE.STRING)) then id = entity.lastFound.value
        end
        if(entity:contains("definitions", TYPE.LIST, TYPE.STRING) and (id == "0" or id == "" or id == "none")) then
            local definitions = entity.lastFound 

            for i=0, definitions.childCount-1 do
                local child = definitions:child(i).value

                if(child == "+farmer") then id = "1" break
                elseif(child == "+fisherman") then id = "2" break
                elseif(child == "+shephers") then id = "3" break
                elseif(child == "+fletcher") then id = "4" break
                elseif(child == "+librarian") then id = "5" break
                elseif(child == "+cartographer") then id = "6" break
                elseif(child == "+cleric") then id = "7" break
                elseif(child == "+armorer") then id = "8" break
                elseif(child == "+weaponsmith") then id = "9" break
                elseif(child == "+toolsmith") then id = "10" break
                elseif(child == "+butcher") then id = "11" break
                elseif(child == "+leatherworker") then id = "12" break
                elseif(child == "+mason") then id = "13" break
                elseif(child == "+nitwit") then id = "14" break
                end
            end
        end
        
        local jobEntry = Database:find(context.edition, "villager_professions", id, "", context.version, -1)

        if(jobEntry ~= nil and jobEntry.valid) then
            Style:setLabel(entity, "Villager (" .. vType .. jobEntry.name .. ")")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/Villager" .. jobEntry.name .. ".png")
        elseif(vType ~= "") then
            Style:setLabel(entity, "Villager (" .. vType:sub(1, -2) .. ")")end
    elseif(context.edition == EDITION.CONSOLE) then
        local id = ""
        local meta = ""

        if(entity:contains("Career", TYPE.INT)) then meta = tostring(entity.lastFound.value) else meta = "1" end
        if(entity:contains("Profession", TYPE.INT)) then id = tostring(entity.lastFound.value) end

        local jobEntry = Database:find(context.edition, "villager_professions", id, meta, context.version, -1)

        if(jobEntry ~= nil and jobEntry.valid) then
            Style:setLabel(entity, "Villager (" .. jobEntry.name .. ")")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/Villager" .. jobEntry.name .. ".png")
        end
    end
end

function EntityInfo.styler:ZombieVillager(entity, context)

    if(context.edition == EDITION.JAVA) then
        local id = ""
        local meta = ""
        local vType = ""

        if(context.version < 1901) then
            if(entity:contains("Career", TYPE.INT)) then meta = tostring(entity.lastFound.value) else meta = "1" end
            if(entity:contains("Profession", TYPE.INT)) then id = tostring(entity.lastFound.value) end
        else
            if(entity:contains("VillagerData", TYPE.COMPOUND)) then
                local vData = entity.lastFound
                if(vData:contains("profession", TYPE.STRING)) then id = vData.lastFound.value end
                if(vData:contains("type", TYPE.STRING)) then
                    vType = vData.lastFound.value

                    if(vType:find("^minecraft:")) then vType = vType:sub(11) end

                    if(vType == "plains") then vType = "Plains "
                    elseif(vType == "desert") then vType = "Desert "
                    elseif(vType == "jungle") then vType = "Jungle "
                    elseif(vType == "savanna") then vType = "Savanna "
                    elseif(vType == "snow") then vType = "Snow "
                    elseif(vType == "swamp") then vType = "Swamp "
                    elseif(vType == "taiga") then vType = "Taiga "
                    else vType = ""
                    end
                end
            end
        end

        local jobEntry = Database:find(context.edition, "villager_professions", id, meta, context.version, -1)

        if(jobEntry ~= nil and jobEntry.valid) then
            Style:setLabel(entity, "Zombie Villager (" .. vType .. jobEntry.name .. ")")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/ZombieVillager" .. jobEntry.name .. ".png")
        elseif(vType ~= "") then
            Style:setLabel(entity, "Zombie Villager (" .. vType:sub(1, -2) .. ")")
        end

    elseif(context.edition == EDITION.BEDROCK) then
        local id = ""
        local vType = ""

        if(entity:contains("MarkVariant", TYPE.INT)) then
            vType = entity.lastFound.value

            if(vType == 0) then vType = "Plains "
            elseif(vType == 1) then vType = "Desert "
            elseif(vType == 2) then vType = "Jungle "
            elseif(vType == 3) then vType = "Savanna "
            elseif(vType == 4) then vType = "Snow "
            elseif(vType == 5) then vType = "Swamp "
            elseif(vType == 6) then vType = "Taiga "
            else vType = ""
            end
        end
        if(entity:contains("Variant", TYPE.INT)) then id = tostring(entity.lastFound.value)
        elseif(entity:contains("PreferredProfession", TYPE.STRING)) then id = entity.lastFound.value
        end
        if(entity:contains("definitions", TYPE.LIST, TYPE.STRING) and (id == "0" or id == "" or id == "none")) then
            local definitions = entity.lastFound 

            for i=0, definitions.childCount-1 do
                local child = definitions:child(i).value

                if(child == "+farmer") then id = "1" break
                elseif(child == "+fisherman") then id = "2" break
                elseif(child == "+shephers") then id = "3" break
                elseif(child == "+fletcher") then id = "4" break
                elseif(child == "+librarian") then id = "5" break
                elseif(child == "+cartographer") then id = "6" break
                elseif(child == "+cleric") then id = "7" break
                elseif(child == "+armorer") then id = "8" break
                elseif(child == "+weaponsmith") then id = "9" break
                elseif(child == "+toolsmith") then id = "10" break
                elseif(child == "+butcher") then id = "11" break
                elseif(child == "+leatherworker") then id = "12" break
                elseif(child == "+mason") then id = "13" break
                elseif(child == "+nitwit") then id = "14" break
                end
            end
        end
        
        local jobEntry = Database:find(context.edition, "villager_professions", id, "", context.version, -1)

        if(jobEntry ~= nil and jobEntry.valid) then
            Style:setLabel(entity, "Zombie Villager (" .. vType .. jobEntry.name .. ")")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/ZombieVillager" .. jobEntry.name .. ".png")
        elseif(vType ~= "") then
            Style:setLabel(entity, "Zombie Villager (" .. vType:sub(1, -2) .. ")")
        end
    elseif(context.edition == EDITION.CONSOLE) then
        local id = ""
        local meta = ""

        if(entity:contains("Career", TYPE.INT)) then meta = tostring(entity.lastFound.value) else meta = "1" end
        if(entity:contains("Profession", TYPE.INT)) then id = tostring(entity.lastFound.value) end
        
        local jobEntry = Database:find(context.edition, "villager_professions", id, meta, context.version, -1)

        if(jobEntry ~= nil and jobEntry.valid) then
            Style:setLabel(entity, "Zombie Villager (" .. jobEntry.name .. ")")
            Style:setIcon(entity, "EntityInfo/images/entity_specific/ZombieVillager" .. jobEntry.name .. ".png")
        end
    end
end

return EntityInfo