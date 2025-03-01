RegisterCommand("showBattlePassAdmin", function(src,args,raw)
    TriggerServerEvent('battlepass:requestData')
end, true)
RegisterCommand('setBattlePass', function(source, args, rawCommand)
    print("aAA")
    TriggerServerEvent("battlepass:getActiveBattlePass")    
end)

RegisterNetEvent('battlepass:activeData', function(activeBattlePass)
    print("Active Battle Pass:", json.encode(activeBattlePass))
    if activeBattlePass then
        -- Varsayılan değerler (örneğin, itemTextureDict ve background için)
        local defaultItemTextureDict = "inventory_items"
        local defaultBackground = "default_background"

        -- activeBattlePass'ten gelen verileri kullanarak seasonData tablosunu oluşturuyoruz:
        local seasonData = {
            seasonPassowned = false,
            passName = activeBattlePass.info.name or "The Halloween Pass 2",
            infoScreen = {
                buyPromptEnabled = true,
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
                    line2 = activeBattlePass.details.body_line2 or [[Second Line qadr_ui
        Second Line qadr_ui
        Second Line qadr_ui
        Second Line qadr_ui
        Second Line qadr_ui]]
                }
            },
            progressPageData = {
                tileTextureDict = activeBattlePass.details.progress_tile_texture_dict or "pm_tiles_progress_mp",
                tileTexture = activeBattlePass.details.progress_tile_texture or "prog_mp_02_quickdraw",
                enabled = activeBattlePass.details.progress_enabled or true,
                tileOverlayVisible = activeBattlePass.details.progress_tile_overlay_visible or true,
                rankTextColor = activeBattlePass.details.progress_rank_text_color or "COLOR_VIP",
                seasonPromptEnabled = true,
                seasonToolTipText = activeBattlePass.details.progress_season_tool_tip_text or "Tooltip Text",
                largeTextureAlpha = activeBattlePass.details.progress_large_texture_alpha or 255,
                largeTextureName = "upgrade_camp_flag_brand_lcola_default_00",
                largeTextureTxd = "upgrade_camp_flag_brand_lcola_default_00"
            },
            playerData = {
                rank = 6,  -- Eğer activeBattlePass.playerData yoksa varsayılan değer
                xp = 60,
                xpmax = 100,
            },
            items = {
                vipItem = {},
                rankItem = {}
            }
        }

        -- activeBattlePass.items dizisini dolaşıp, kategoriye göre seasonData.items tablolarına ekleyelim:
        for _, item in ipairs(activeBattlePass.items or {}) do
            local mappedItem = {
                itemTexture = item.itemTexture,
                itemTextureDict = item.itemTextureDict,
                selectedBackgroundTexture = item.selectedBackgroundTexture,
                selectedBackgroundTextureDict = item.selectedBackgroundTextureDict,
                label = item.label,
                description = item.description,
                owned = item.owned,
                rank = item.rank,
                tooltipRawText = item.tooltipRawText or item.label
            }
            
            if item.category == "free" then
                table.insert(seasonData.items.rankItem, mappedItem)
            else
                table.insert(seasonData.items.vipItem, mappedItem)
            end
        end
        exports["qadr_ui"]:seasonrewards(seasonData)
        -- Burada UI güncellemesi ya da diğer işlemleri gerçekleştirebilirsiniz.
    else
        print("Aktif battle pass bulunamadı!")
    end
end)


-- Client tarafında veriyi sunucudan çekmek için
Citizen.CreateThread(function()
    
end)

-- Sunucudan veri geldiğinde yakalayalım
RegisterNetEvent('battlepass:sendData')
AddEventHandler('battlepass:sendData', function(data)
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

-- NUI'den gelecek event'leri yakalamak isterseniz (Örn: butona basınca kapatma)
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- NUI callback: Yeni battle pass verisini alır ve sunucuya gönderir.
RegisterNUICallback('deleteBattlePass', function(data, cb)    
    TriggerServerEvent('battlepass:deleteBattlePass', data.id)
    cb('ok')
end)
RegisterNUICallback('savePass', function(data, cb)
    -- data: Yeni battle pass verisini içeren JSON objesi
    TriggerServerEvent('battlepass:saveData', data)
    -- Client'a basit bir geri dönüş (opsiyonel)
    cb({ status = 'veri gönderildi' })
end)
