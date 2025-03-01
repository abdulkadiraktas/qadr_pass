-- Global cache değişkeni
local battlepassCache = {}

-- Cache'i veritabanından yükleyen fonksiyon
local function loadBattlePassCache()
    -- battle_passes tablosunu çekiyoruz
    MySQL.query('SELECT * FROM battle_passes', {}, function(battlePasses)
        if battlePasses then
            -- battle_pass_details tablosunu çekelim
            MySQL.query('SELECT * FROM battle_pass_details', {}, function(details)
                -- battle_pass_items tablosunu çekelim
                MySQL.query('SELECT * FROM battle_pass_items', {}, function(items)
                    -- battle_pass_details verilerini battle_pass_id bazında gruplama
                    local detailsLookup = {}
                    for _, detail in ipairs(details) do
                        detailsLookup[detail.battle_pass_id] = detail
                    end

                    -- battle_pass_items verilerini battle_pass_id bazında gruplama
                    local itemsLookup = {}
                    for _, item in ipairs(items) do
                        if not itemsLookup[item.battle_pass_id] then
                            itemsLookup[item.battle_pass_id] = {}
                        end
                        table.insert(itemsLookup[item.battle_pass_id], item)
                    end

                    -- Tüm battle_passes verilerini detay ve item bilgileriyle birleştiriyoruz
                    local combinedData = {}
                    for _, bp in ipairs(battlePasses) do
                        local bpData = {
                            info = bp,
                            details = detailsLookup[bp.id] or {},
                            items = itemsLookup[bp.id] or {}
                        }
                        table.insert(combinedData, bpData)
                    end

                    battlepassCache = combinedData
            
                end)
            end)
        else
            battlepassCache = {}
        end
    end)
end
-- Kaynak başladığında cache'i yükle
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadBattlePassCache()
    end
end)
-- (Opsiyonel) Cache'i yenilemek için sunucu event'i
RegisterNetEvent('battlepass:refreshCache')
AddEventHandler('battlepass:refreshCache', function()
    loadBattlePassCache()
end)
-- İstemciden veri isteği geldiğinde cache'deki veriyi gönder
RegisterNetEvent('battlepass:requestData')
AddEventHandler('battlepass:requestData', function()
    local src = source
    if battlepassCache and #battlepassCache > 0 then
        TriggerClientEvent('battlepass:sendData', src, battlepassCache)
    else
        TriggerClientEvent('battlepass:sendData', src, {})
    end
end)
-- NUI üzerinden gelen battle pass verisini DB'ye kaydeder
RegisterNetEvent('battlepass:saveData')
AddEventHandler('battlepass:saveData', function(data)
    local src = source
    -- Gelen JSON yapısını parçalayalım:
    local general    = data.general    -- passName, buyPromptText, seasonStart, seasonEnd, body (title, line1, line2)
    local visuals    = data.visuals    -- background, logo, progressPage
    local items      = data.items      -- premium ve free dizileri
    -- Diğer alanlar (seasonPassowned, infoScreen, progressPageData, playerData) ihtiyaç halinde ayrı tabloda saklanabilir

    -- Örnek ID üretimi: timestamp bazlı string (üretim şeklinizi geliştirebilirsiniz)
    local passId = tostring(os.time())
    local function convertDateStringToTimestamp(dateString)
        local year, month, day = dateString:match("(%d+)%-(%d+)%-(%d+)")
        return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
    end
    local nowTimestamp = os.time()
    local startTimestamp = convertDateStringToTimestamp(general.seasonStart)
    local endTimestamp = convertDateStringToTimestamp(general.seasonEnd)
    local status = 'upcoming'
    if nowTimestamp >= startTimestamp and nowTimestamp <= endTimestamp then
        status = 'active'
    elseif nowTimestamp > endTimestamp then
        status = 'completed'
    else
        status = 'upcoming'
    end
    -- 1) battle_passes tablosuna ekleme (total_players, premium_players default 0; status örneğin "upcoming")
    MySQL.insert(
        'INSERT INTO battle_passes (id, name, start_date, end_date, total_players, premium_players, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { passId, general.passName, general.seasonStart, general.seasonEnd, 0, 0, status },
        function(battlePassInsertId)
            if battlePassInsertId then
                -- 2) battle_pass_details tablosuna ekleme
                MySQL.insert(
                    'INSERT INTO battle_pass_details (battle_pass_id, buy_prompt_text, background_dict, background_texture, background_gradient_dict, background_gradient_texture, logo_dict, logo_texture, body_title, body_line1, body_line2, progress_tile_texture_dict, progress_tile_texture, progress_rank_text_color, progress_large_texture_alpha, progress_enabled, progress_tile_overlay_visible, progress_season_tool_tip_text) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    {
                        passId,
                        general.buyPromptText,
                        visuals.background.dict,
                        visuals.background.texture,
                        visuals.background.gradient.dict,
                        visuals.background.gradient.texture,
                        visuals.logo.dict,
                        visuals.logo.texture,
                        general.body.title,
                        general.body.line1,
                        general.body.line2,
                        visuals.progressPage.tileTextureDict,
                        visuals.progressPage.tileTexture,
                        visuals.progressPage.rankTextColor,
                        visuals.progressPage.largeTextureAlpha,
                        visuals.progressPage.enabled and 1 or 0,
                        visuals.progressPage.tileOverlayVisible and 1 or 0,
                        visuals.progressPage.seasonToolTipText
                    },
                    function(detailInsertId)
                        -- 3) battle_pass_items tablosuna premium ve free item'larını ekleyelim
                        local totalItems = 0
                        local processedItems = 0
                        local itemsArray = {}

                        if items.premium then
                            for _, item in ipairs(items.premium) do
                                totalItems = totalItems + 1
                                table.insert(itemsArray, { category = 'premium', item = item })
                            end
                        end
                        if items.free then
                            for _, item in ipairs(items.free) do
                                totalItems = totalItems + 1
                                table.insert(itemsArray, { category = 'free', item = item })
                            end
                        end

                        -- Eğer eklenmesi gereken item yoksa, direk başarılı dönüş gönderelim.
                        if totalItems == 0 then
                            TriggerClientEvent('battlepass:saveResult', src, { success = true })
                        else
                            for _, entry in ipairs(itemsArray) do
                                local cat = entry.category
                                local item = entry.item
                                MySQL.insert(
                                    'INSERT INTO battle_pass_items (battle_pass_id, category, itemTexture, itemTextureDict, selectedBackgroundTexture, selectedBackgroundTextureDict, label, description, `rank`, owned) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                    { passId, cat, item.itemTexture, item.itemTextureDict,  item.selectedBackgroundTexture, item.selectedBackgroundTextureDict,item.label, item.description, item.rank, item.owned and 1 or 0 },
                                    function(itemInsertId)
                                        processedItems = processedItems + 1
                                        if processedItems == totalItems then
                                            TriggerClientEvent('battlepass:saveResult', src, { success = true })
                                        end
                                    end
                                )
                            end
                        end
                    end
                )
            else
                TriggerClientEvent('battlepass:saveResult', src, { success = false, error = "Battle pass insert failed" })
            end
        end
    )
    -- SQL'e eklenen verileri cache'e de ekleyelim
    local newPassData = {
        info = {
            id = passId,
            name = general.passName,
            start_date = general.seasonStart,
            end_date = general.seasonEnd,
            total_players = 0,
            premium_players = 0,
            status = status
        },
        details = {
            buy_prompt_text = general.buyPromptText,
            background_dict = visuals.background.dict,
            background_texture = visuals.background.texture,
            background_gradient_dict = visuals.background.gradient.dict,
            background_gradient_texture = visuals.background.gradient.texture,
            logo_dict = visuals.logo.dict,
            logo_texture = visuals.logo.texture,
            body_title = general.body.title,
            body_line1 = general.body.line1,
            body_line2 = general.body.line2,
            progress_tile_texture_dict = visuals.progressPage.tileTextureDict,
            progress_tile_texture = visuals.progressPage.tileTexture,
            progress_rank_text_color = visuals.progressPage.rankTextColor,
            progress_large_texture_alpha = visuals.progressPage.largeTextureAlpha,
            progress_enabled = visuals.progressPage.enabled,
            progress_tile_overlay_visible = visuals.progressPage.tileOverlayVisible,
            progress_season_tool_tip_text = visuals.progressPage.seasonToolTipText
        },
        items = {}
    }
    if items.premium then
        for _, item in ipairs(items.premium) do
            table.insert(newPassData.items, { category = 'premium', item = item })
        end
    end
    if items.free then
        for _, item in ipairs(items.free) do
            table.insert(newPassData.items, { category = 'free', item = item })
        end
    end
    table.insert(battlepassCache, newPassData)
    if battlepassCache and #battlepassCache > 0 then
        TriggerClientEvent('battlepass:sendData', src, battlepassCache)
    else
        TriggerClientEvent('battlepass:sendData', src, {})
    end
end)
function convertDateStringToTimestamp(dateString)
    print(type(dateString), dateString)
    if dateString then
        -- body
        local year, month, day = dateString:match("(%d+)%-(%d+)%-(%d+)")
        return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
    end
end

function getActiveBattlePass()
    local nowTimestamp = os.time()
    local activeBattlePass = nil 
    for _, bp in ipairs(battlepassCache or {}) do
        local startTimestamp = convertDateStringToTimestamp(tostring(bp.info.start_date))
        local endTimestamp = convertDateStringToTimestamp(tostring(bp.info.end_date))
        if nowTimestamp >= startTimestamp and nowTimestamp <= endTimestamp then
            activeBattlePass = bp
            break  -- Aynı anda sadece 1 tane pass aktif olabilir.
        end
    end
    return activeBattlePass
end

RegisterNetEvent('battlepass:getActiveBattlePass')
AddEventHandler('battlepass:getActiveBattlePass', function()
    local src = source    
    print("bura",src)
    if src ~= 0 then 
        print("bura",src)
        local nowTimestamp = os.time()
        local activeBattlePass = nil
        
        -- Yardımcı fonksiyon: Giriş değeri string veya number olabilir.
        local function getTimestamp(dateValue)
            if type(dateValue) == "string" then
                local year, month, day = dateValue:match("(%d+)%-(%d+)%-(%d+)")
                if year and month and day then
                    return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
                else
                    return nil
                end
            elseif type(dateValue) == "number" then
                -- Eğer sayı çok büyükse (ör. 13 haneli) milisaniye kabul edip saniyeye çeviriyoruz.
                if dateValue > 1e10 then
                    return math.floor(dateValue / 1000)
                else
                    return dateValue
                end
            end
            return nil
        end
        
        print("bura")
        for _, bp in ipairs(battlepassCache or {}) do
            local startTimestamp = getTimestamp(bp.info.start_date)
            local endTimestamp = getTimestamp(bp.info.end_date)
            if startTimestamp and endTimestamp then
                if nowTimestamp >= startTimestamp and nowTimestamp <= endTimestamp then
                    activeBattlePass = bp
                    break  -- Aynı anda sadece 1 pass aktif olabilir.
                end
            end
        end

        TriggerClientEvent('battlepass:activeData', src, activeBattlePass)
        print("bura")

    end
end)
RegisterNetEvent('battlepass:deleteBattlePass')
AddEventHandler('battlepass:deleteBattlePass', function(passId)
    local src = source
    if not passId then
        TriggerClientEvent('battlepass:deleteResult', src, { success = false, error = "Geçersiz battle pass id" })
        return
    end
    -- Öncelikle battle_pass_items tablosundan ilgili kayıtları silelim
    MySQL.update('DELETE FROM battle_pass_items WHERE battle_pass_id = ?', { passId }, function(affectedItems)
        -- Sonrasında battle_pass_details tablosundan silme işlemi
        MySQL.update('DELETE FROM battle_pass_details WHERE battle_pass_id = ?', { passId }, function(affectedDetails)
            -- En son battle_passes tablosundan silme işlemi
            MySQL.update('DELETE FROM battle_passes WHERE id = ?', { passId }, function(affectedPass)
                if affectedPass > 0 then
                    -- Cache güncellemesi: silinen pass cache'den de çıkarılıyor
                    for i, bp in ipairs(battlepassCache or {}) do
                        if bp.info.id == tostring(passId) then
                            table.remove(battlepassCache, i)
                            break
                        end
                    end
                    TriggerClientEvent('battlepass:deleteResult', src, { success = true })
                else
                    TriggerClientEvent('battlepass:deleteResult', src, { success = false, error = "Battle pass bulunamadı" })
                end
            end)
        end)
    end)
end)

AddEventHandler("redemrp:playerLoaded",function(source, user)
    local src = source
    TriggerClientEvent('battlepass:activeData', src, getActiveBattlePass())
end)
