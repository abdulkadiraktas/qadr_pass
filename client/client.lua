local tempDicts = {}

-- @description: This command triggers a server event to request battle pass data.
-- @param: src - The source of the command (player ID).
-- @param: args - Arguments passed to the command.
-- @param: raw - The raw command string.
-- @usage: /showBattlePassAdmin
RegisterCommand("showBattlePassAdmin", function(src,args,raw)
    TriggerServerEvent('qadr_pass:requestData')
end, true)

-- @description: This command triggers a server event to get the active battle pass data.
-- @param: source - The source of the command (player ID).
-- @param: args - Arguments passed to the command.
-- @param: rawCommand - The raw command string.
-- @usage: /setBattlePass
RegisterCommand('setBattlePass', function(source, args, rawCommand)
    TriggerServerEvent("qadr_pass:getActiveBattlePass")    
end)

-- @description: This event triggers a server event to get the active battle pass data.
-- @event: qadr_pass:triggerClientforGettinBattlePass
RegisterNetEvent("qadr_pass:triggerClientforGettinBattlePass")
AddEventHandler("qadr_pass:triggerClientforGettinBattlePass", function()
    TriggerServerEvent("qadr_pass:getActiveBattlePass")
end)

-- @description: This event receives active battle pass data from the server and processes it to update the UI.
-- @event: qadr_pass:activeData
-- @param: activeBattlePass - The active battle pass data.
RegisterNetEvent('qadr_pass:activeData', function(activeBattlePass)    
    if activeBattlePass then
        -- Varsayılan değerler (örneğin, itemTextureDict ve background için)
        local defaultItemTextureDict = "inventory_items"
        local defaultBackground = "default_background"
        -- activeBattlePass'ten gelen verileri kullanarak seasonData tablosunu oluşturuyoruz:
        local seasonData = {
            seasonPassowned = activeBattlePass?.user?.seasonPassOwned or false,
            passName = activeBattlePass.info.name or "The Halloween Pass 2",
            infoScreen = {
                buyPromptEnabled = not activeBattlePass?.user?.seasonPassOwned,
                buyPromptText = activeBattlePass.details.buy_prompt_text or "Prompt Text",
                page = 0,
                background = {
                    dict = activeBattlePass.details.background_dict or "default_bg",
                    texture = activeBattlePass.details.background_texture or "default_texture",
                    gradient = {
                        dict = activeBattlePass.details.background_gradient_dict or "default_gradient_dict",
                        texture = activeBattlePass.details.background_gradient_texture or "default_gradient_texture"
                    }
                },
                logo = {
                    dict = activeBattlePass.details.logo_dict or "default_logo_dict",
                    texture = activeBattlePass.details.logo_texture or "default_logo_texture"
                },
                body = {
                    title = activeBattlePass.details.body_title or "Bodys Title",
                    line1 = activeBattlePass.details.body_line1 or "First Line qadr_ui",
                    line2 = activeBattlePass.details.body_line2 or "Second Line qadr_ui",
                }
            },
            progressPageData = {
                tileTextureDict = activeBattlePass.details.progress_tile_texture_dict or "pm_tiles_progress_mp",
                tileTexture = activeBattlePass.details.progress_tile_texture or "prog_mp_02_quickdraw",
                enabled = activeBattlePass.details.progress_enabled or false,
                tileOverlayVisible = activeBattlePass?.user?.seasonPassOwned or false,
                --rankTextColor = activeBattlePass.details.progress_rank_text_color or "COLOR_VIP",
                -- activeBattlePass?.user?.seasonPassOwned bu true ise "COLOR_VIP" değilse "COLOR_WHITE" olacak
                rankTextColor = activeBattlePass?.user?.season
                    and activeBattlePass.details.progress_rank_text_color or "COLOR_VIP",
                seasonPromptEnabled = true, -- Eğer active pass yoksa false olcak sonra yapıcam
                seasonToolTipText = activeBattlePass.details.progress_season_tool_tip_text or "Tooltip Text",
                largeTextureAlpha = activeBattlePass.details.progress_large_texture_alpha or 255,
                largeTextureName = "upgrade_camp_flag_brand_lcola_default_00",
                largeTextureTxd = "upgrade_camp_flag_brand_lcola_default_00"
            },
            playerData = {
                rank = activeBattlePass?.user?.rank or 0,  -- Eğer activeBattlePass.playerData yoksa varsayılan değer
                xp = activeBattlePass?.user?.xp or 0,
                xpmax = activeBattlePass?.user?.xpmax or 0,
            },
            items = {
                vipItem = {},
                rankItem = {}
            }
        }
        -- activeBattlePass.items dizisini dolaşıp, kategoriye göre seasonData.items tablolarına ekleyelim:
        for _, item in pairs(activeBattlePass.items or {}) do
            local owned = false
            if activeBattlePass.userItems then 
                for k,l in pairs(activeBattlePass.userItems) do
                    if l.item_id == item.item_id then
                        owned = true
                        break
                    end
                end
            end
            local mappedItem = {
                itemTexture = item.itemTexture,
                itemTextureDict = item.itemTextureDict,
                selectedBackgroundTexture = item.selectedBackgroundTexture,
                selectedBackgroundTextureDict = item.selectedBackgroundTextureDict,
                label = item.label,
                description = item.description,
                owned = owned,
                rank = item.rank,
                tooltipRawText = item.tooltipRawText or item.label,
                rewards = item.rewards,
                itemId = item.item_id,
                battle_pass_id = item.battle_pass_id,
            } 
            table.insert(tempDicts, item.itemTextureDict)           
            table.insert(tempDicts, item.selectedBackgroundTextureDict)           
            if item.category == "free" then
                table.insert(seasonData.items.rankItem, mappedItem)
            else
                table.insert(seasonData.items.vipItem, mappedItem)
            end
        end        
        print(json.encode(seasonData),"seasonData")
        exports["qadr_ui"]:seasonrewards(seasonData)
        -- Burada UI güncellemesi ya da diğer işlemleri gerçekleştirebilirsiniz.
        table.insert(tempDicts, activeBattlePass.details.background_dict)
        table.insert(tempDicts, activeBattlePass.details.background_gradient_dict)
        table.insert(tempDicts, activeBattlePass.details.logo_dict)
        table.insert(tempDicts, activeBattlePass.details.progress_tile_texture_dict)
    else
        exports["qadr_ui"]:seasonrewards()        
    end
    table.insert(tempDicts, defaultItemTextureDict)
end)

-- @description: This event receives updated XP data from the server and updates the UI.
-- @event: qadr_pass:updateXP
-- @param: data - The updated XP data.
RegisterNetEvent("qadr_pass:updateXP")
AddEventHandler("qadr_pass:updateXP", function(data)
    print(json.encode(data),"updateXP")    
    local currentPass = exports["qadr_ui"]:qadr_ui_get_current_seasonpass()
    -- data = {
    --     xp = currentXP,
    --     rank = currentRank,
    --     xpmax = xpRequired
    -- }
    currentPass:update({
        playerData = {
            xp = data.xp,
            rank = data.rank,
            xpmax = data.xpmax
        }
    })
end)

-- @description: This event receives the result of an item purchase attempt from the server.
-- @event: qadr_pass:purchaseResult
-- @param: data - The result data.
RegisterNetEvent('qadr_pass:passPurchase')
AddEventHandler('qadr_pass:passPurchase', function(data)
    local currentPass = exports["qadr_ui"]:qadr_ui_get_current_seasonpass()
    currentPass:update({
        seasonPassowned = data.seasonPassOwned
    })
end)


-- @description: This event receives the result of an item collection attempt from the server.
-- @event: qadr_pass:collectResult
-- @param: data - The result data.
RegisterNetEvent('qadr_pass:collectResult')
AddEventHandler('qadr_pass:collectResult', function(data)
    print(json.encode(data),"collectResult")    
end)

-- @description: This event receives battle pass data from the server and sends it to the NUI.
-- @event: qadr_pass:sendData
-- @param: data - The battle pass data.
RegisterNetEvent('qadr_pass:sendData')
AddEventHandler('qadr_pass:sendData', function(data)    
    -- data = MySQL'den gelen satırların listesi
    -- Bunu NUI'ye (HTML/JS) gönderelim:
    SendNUIMessage({
        action = 'loadBattlePasses',
        battlePasses = data
    })
    -- İsterseniz UI'yi açmak için bir komut veya event tetikleyebilirsiniz
    -- Örnek: Arayüzü açmak için
    SetNuiFocus(true, true) -- Mouse & klavye odaklanma
end)

-- @description: This event is triggered when the resource stops and resets default icon visibility.
-- @event: onResourceStop
-- @param: resourceName - The name of the resource that is stopping.
AddEventHandler('onResourceStop', function(resourceName) -- this side set default icon visibility when resource stop
    if (GetCurrentResourceName() == resourceName) then
        exports["qadr_ui"]:seasonrewards()
        if tempDict then
            for k,l in pairs(tempDict)do	
                if type(l) == "table" then
                    for m,n in pairs(l)do
                        if cin(0x54D6900929CCF162,n) then
                            cin(0x8232F37DF762ACB2,n)
                        end
                    end
                else
                    if cin(0x54D6900929CCF162,l) then
                        cin(0x8232F37DF762ACB2,l)
                    end
                end
            end
        end
    end
end)

-- @description: This NUI callback closes the UI.
-- @callback: closeUI
-- @param: data - Data from the NUI.
-- @param: cb - Callback function.
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- @description: This NUI callback deletes a battle pass.
-- @callback: deleteBattlePass
-- @param: data - Data from the NUI, including the battle pass ID.
-- @param: cb - Callback function.
RegisterNUICallback('deleteBattlePass', function(data, cb)    
    TriggerServerEvent('qadr_pass:deleteBattlePass', data.id)
    cb('ok')
end)

-- @description: This NUI callback saves a new battle pass.
-- @callback: savePass
-- @param: data - Data from the NUI, including the new battle pass data.
-- @param: cb - Callback function.
RegisterNUICallback('savePass', function(data, cb)
    -- data: Yeni battle pass verisini içeren JSON objesi
    TriggerServerEvent('qadr_pass:saveData', data)
    -- Client'a basit bir geri dönüş (opsiyonel)
    cb({ status = 'veri gönderildi' })
end)

-- @description: This NUI callback updates an existing battle pass.
-- @callback: updatePass
-- @param: data - Data from the NUI, including the updated battle pass data.
-- @param: cb - Callback function.
RegisterNUICallback('updatePass', function(data, cb)
    -- data: Yeni battle pass verisini içeren JSON objesi
    TriggerServerEvent('qadr_pass:updateData', data)
    -- Client'a basit bir geri dönüş (opsiyonel)
    cb({ status = 'veri gönderildi' })
end)
