-- Global cache değişkeni
local battlepassCache = {}
local cachetimer = 10000
-- At the top of the file...
RedEM = exports["redem_roleplay"]:RedEM()
data = {}
TriggerEvent("redemrp_inventory:getData",function(call)
    data = call
end)

-- @description Converts a date string or timestamp to a timestamp.
-- @param dateValue string|number The date string in "YYYY-MM-DD" format or a timestamp.
-- @param isEnd boolean If true, sets the time to the end of the day (23:59:59).
-- @return number|nil The timestamp or nil if the date string is invalid.
local function getTimestamp(dateValue, isEnd)
    if type(dateValue) == "string" then
        local year, month, day = dateValue:match("(%d+)%-(%d+)%-(%d+)")
        if year and month and day then
            return os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = isEnd and 23 or 0,
                min = isEnd and 59 or 0,
                sec = isEnd and 59 or 0
            })
        else
            return nil
        end
    elseif type(dateValue) == "number" then
        local ts = nil
        if dateValue > 1e10 then
            ts = math.floor(dateValue / 1000)
        else
            ts = dateValue
        end
        if isEnd then
            ts = ts + 86399  -- End date için gün sonunu ekliyoruz.
        end
        return ts
    end
    return nil
end

-- @description Loads and caches battle pass data from the database.
local function loadBattlePassCache()
    local tempCache = {}
    local battlePasses, details, items, users, userItems
    local queriesCompleted = 0

    -- @description Checks if all database queries are completed and combines the results.
    local function checkAndCombine()
        queriesCompleted = queriesCompleted + 1
        if queriesCompleted == 5 then -- tüm sorgular tamamlandıysa birleştir
            local detailsLookup, itemsLookup, usersLookup, userItemsLookup = {}, {}, {}, {}

            for _, detail in ipairs(details) do
                detailsLookup[detail.battle_pass_id] = detail
            end

            for _, item in ipairs(items) do
                itemsLookup[item.battle_pass_id] = itemsLookup[item.battle_pass_id] or {}
                table.insert(itemsLookup[item.battle_pass_id], item)
            end

            for _, user in ipairs(users) do
                usersLookup[user.battle_pass_id] = usersLookup[user.battle_pass_id] or {}
                usersLookup[user.battle_pass_id][user.user_id] = user
            end

            for _, userItem in ipairs(userItems) do
                userItemsLookup[userItem.battle_pass_id] = userItemsLookup[userItem.battle_pass_id] or {}
                table.insert(userItemsLookup[userItem.battle_pass_id], userItem)
            end

            for _, bp in ipairs(battlePasses) do
                local bpData = {
                    info = bp,
                    details = detailsLookup[bp.id] or {},
                    items = itemsLookup[bp.id] or {},
                    users = usersLookup[bp.id] or {},
                    userItems = userItemsLookup[bp.id] or {}
                }
                table.insert(tempCache, bpData)
            end

            -- Atomik olarak cache'i güncelle
            battlepassCache = tempCache
        end
    end

    local nowTimestamp = os.time()
    MySQL.query('SELECT * FROM battle_passes', {}, function(result)
        battlePasses = result or {}
        for _, bp in ipairs(battlePasses) do
            local startTimestamp = getTimestamp(bp.start_date, false)
            local endTimestamp = getTimestamp(bp.end_date, true)
            if startTimestamp and endTimestamp then
                local newStatus
                if nowTimestamp < startTimestamp then
                    newStatus = "upcoming"
                elseif nowTimestamp > endTimestamp then
                    newStatus = "completed"
                else
                    newStatus = "active"
                end
                if newStatus ~= bp.status then
                    MySQL.update('UPDATE battle_passes SET status = ? WHERE id = ?', { newStatus, bp.id })
                    bp.status = newStatus
                end
            end
        end
        checkAndCombine()
    end)

    MySQL.query('SELECT * FROM battle_pass_details', {}, function(result)
        details = result or {}
        checkAndCombine()
    end)

    MySQL.query('SELECT * FROM battle_pass_items', {}, function(result)
        items = result or {}
        checkAndCombine()
    end)

    MySQL.query('SELECT * FROM battle_pass_users', {}, function(result)
        users = result or {}
        checkAndCombine()
    end)

    MySQL.query('SELECT * FROM battle_pass_user_items', {}, function(result)
        userItems = result or {}
        checkAndCombine()
    end)
end

-- @description Converts a date string in "YYYY-MM-DD" format to a timestamp.
-- @param dateString string The date string to convert.
-- @return number|nil The timestamp or nil if the date string is invalid.
local function convertDateStringToTimestamp(dateString)
    if dateString then
        local year, month, day = dateString:match("(%d+)%-(%d+)%-(%d+)")
        return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
    end
end

-- @description Gets the active battle pass data for a specific user.
-- @param source number|nil The player source (optional).
-- @return table|nil The active battle pass data or nil if no active pass is found.
local function getActiveBattlePassforUser(source)
    local nowTimestamp = os.time()
    local selectedUserPassData = nil
    for _, bp in ipairs(battlepassCache or {}) do
        local startTimestamp = getTimestamp(bp.info.start_date, false)
        local endTimestamp = getTimestamp(bp.info.end_date, true)  -- true olarak geçiriyoruz
        if startTimestamp and endTimestamp then
            if nowTimestamp >= startTimestamp and nowTimestamp <= endTimestamp then
                selectedUserPassData = deepCopy(bp)
                break  -- Aynı anda sadece 1 pass aktif olabilir.
            end
        end
    end
    if source then 
        local Player = RedEM.GetPlayer(source)
        local userid = Player.identifier .. "_" .. Player.charid     
        if selectedUserPassData then
            -- İlgili battle pass içindeki tüm kullanıcı verilerinden yalnızca istekte bulunan kullanıcıyı filtrele
            local filteredUser = nil
            if selectedUserPassData.users then
                for k,l in pairs(selectedUserPassData.users) do
                    
                    if k == userid then
                        filteredUser = l
                        break
                    end
                end
            end
            
            selectedUserPassData.users = nil
            selectedUserPassData.user = filteredUser
        end
    end
    -- 
    -- for k,l in pairs(selectedUserPassData.userItems)do
    --     selectedUserPassData.items[tostring(l.item_id)].owned = true
    -- end
    return selectedUserPassData
end

-- @description Creates a deep copy of a table.
-- @param original table The table to copy.
-- @return table The deep copy of the table.
function deepCopy(original)
    local orig_type = type(original)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, original, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- @description Creates a battle pass user record if it doesn't exist.
-- @param source number The player source.
local function createBattlePassUserIfNotExists(source)
    local Player = RedEM.GetPlayer(source)
    local userid = Player.identifier .. "_" .. Player.charid

    -- Aktif battle pass'i alıyoruz
    local activeBattlePass = getActiveBattlePassforUser(source)
    if not activeBattlePass then
        
        return
    end

    local bpID = activeBattlePass.info.id
    -- battle_pass_users tablosunda kullanıcının kaydını kontrol ediyoruz
    MySQL.query("SELECT * FROM battle_pass_users WHERE user_id = ? AND battle_pass_id = ?", { userid, bpID }, function(result)
        if not result or #result == 0 then
            -- Eğer kayıt yoksa, varsayılan değerlerle yeni kayıt ekliyoruz
            MySQL.query("INSERT INTO battle_pass_users (user_id, battle_pass_id, `rank`, xp, xpmax, seasonPassOwned) VALUES (?, ?, ?, ?, ?, ?)", 
                { userid, bpID, 0, 0, 100, 0 }, function(insertResult)
                    
                end)
        else
            
        end
    end)
    -- oluşturulan kullanıcı kaydını battlepassCache'e de ekleyelim

    for _, bp in ipairs(battlepassCache or {}) do
        if bp.info.id == bpID then
            if not bp.users then
                bp.users = {}
            end
            if not bp.users[userid] then
                bp.users[userid] = { rank = 0, xp = 0, xpmax = 100, seasonPassOwned = 0 }
            end
            break
        end
    end

end

-- @param source number The source of the player.
-- @param earnedXP number The amount of XP earned.
local function addPlayerPassXP(source, earnedXP)
    local Player = RedEM.GetPlayer(source)
    if not Player then return end
    
    local userid = Player.identifier .. "_" .. Player.charid
    local activePass = getActiveBattlePassforUser(source)

    if not activePass or not activePass.user then
        print("Aktif pass veya kullanıcı bulunamadı.")
        return
    end

    local userPassData = activePass.user
    local currentXP = userPassData.xp or 0
    local currentRank = userPassData.rank or 0
    local xpRequired = userPassData.xpmax or 100

    currentXP = currentXP + earnedXP

    -- Rank yükseltme kontrolü
    while currentXP >= xpRequired do
        currentXP = currentXP - xpRequired
        currentRank = currentRank + 1
        xpRequired = xpRequired + 100 -- Her rank için 100 XP artır, dilersen formülü değiştirebilirsin
    end

    -- Güncellemeyi önce veritabanına kaydedelim
    MySQL.update('UPDATE battle_pass_users SET xp = ?, `rank` = ?, xpmax = ? WHERE user_id = ? AND battle_pass_id = ?', {
        currentXP,
        currentRank,
        xpRequired,
        userid,
        activePass.info.id
    }, function(rowsAffected, error)
        if error then
            print("XP güncelleme hatası:", error)
        elseif rowsAffected > 0 then
            -- Cache'i de güncelle
            for _, bp in ipairs(battlepassCache) do
                if bp.info.id == activePass.info.id then
                    if bp.users and bp.users[userid] then
                        bp.users[userid].xp = currentXP
                        bp.users[userid].rank = currentRank
                        bp.users[userid].xpmax = xpRequired
                    end
                    break
                end
            end

            -- Kullanıcıya bilgi gönder (client event)
            TriggerClientEvent('qadr_pass:updateXP', source, {
                xp = currentXP,
                rank = currentRank,
                xpmax = xpRequired
            })
        end
    end)
end

-- @description: This event is triggered when the resource starts. It initializes a thread that periodically updates the battle pass cache.
-- @event: onResourceStart
-- @param: resourceName - The name of the resource that is starting.
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Citizen.CreateThread(function()
            while true do
                loadBattlePassCache()  -- Cache'i güncelle
                Citizen.Wait(cachetimer)    -- 60000 milisaniye = 60 saniye bekle
            end
        end)
    end
end)

-- @description: This event is triggered to refresh the battle pass cache.
-- @event: qadr_pass:refreshCache
RegisterNetEvent('qadr_pass:refreshCache')
AddEventHandler('qadr_pass:refreshCache', function()
    loadBattlePassCache()
end)

-- @description: This event is triggered to request battle pass data. It sends the battle pass cache to the client.
-- @event: qadr_pass:requestData
RegisterNetEvent('qadr_pass:requestData')
AddEventHandler('qadr_pass:requestData', function()
    local src = source
    if battlepassCache and #battlepassCache > 0 then
        TriggerClientEvent('qadr_pass:sendData', src, battlepassCache)
    else
        TriggerClientEvent('qadr_pass:sendData', src, {})
    end
end)

-- @description: This event is triggered to update battle pass data. It updates the battle pass data in the database and refreshes the cache.
-- @event: qadr_pass:updateData
-- @param: data - The updated battle pass data.
RegisterNetEvent('qadr_pass:updateData')
AddEventHandler('qadr_pass:updateData', function(data)
    local src = source
    local passId = data.id

    local visuals = data.visuals
    local general = data.general
    local progress = visuals.progressPage
    local items = data.items

    -- 1) battle_passes tablosunu güncelle
    MySQL.update(
        'UPDATE battle_passes SET name = ?, start_date = ?, end_date = ? WHERE id = ?',
        { general.passName, general.seasonStart, general.seasonEnd, passId },
        function(affectedRows)
            if affectedRows > 0 then
                -- 2) battle_pass_details tablosunu güncelle
                MySQL.update(
                    [[UPDATE battle_pass_details SET
                        buy_prompt_text = ?,
                        background_dict = ?,
                        background_texture = ?,
                        background_gradient_dict = ?,
                        background_gradient_texture = ?,
                        logo_dict = ?,
                        logo_texture = ?,
                        body_title = ?,
                        body_line1 = ?,
                        body_line2 = ?,
                        progress_tile_texture_dict = ?,
                        progress_tile_texture = ?,
                        progress_rank_text_color = ?,
                        progress_large_texture_dict = ?,
                        progress_large_texture = ?,
                        progress_large_texture_alpha = ?,
                        progress_enabled = ?,
                        progress_tile_overlay_visible = ?,
                        progress_season_tool_tip_text = ?
                    WHERE battle_pass_id = ?]],
                    {
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
                        progress.tileTextureDict,
                        progress.tileTexture,
                        progress.rankTextColor,
                        progress.largeTextureTxd,
                        progress.largeTextureName,
                        progress.largeTextureAlpha,
                        progress.enabled and 1 or 0,
                        progress.tileOverlayVisible and 1 or 0,
                        progress.seasonToolTipText,
                        passId
                    },
                    function(detailsAffectedRows)
                        if detailsAffectedRows > 0 then
                            -- 3) Eski item'ları silelim ve yeni item'ları ekleyelim
                            MySQL.update('DELETE FROM battle_pass_items WHERE battle_pass_id = ?', {passId}, function(deletedItems)
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

                                if totalItems == 0 then
                                    TriggerClientEvent('battlepass:updateResult', src, { success = true })
                                    TriggerEvent('battlepass:refreshCache')
                                else
                                    for _, entry in ipairs(itemsArray) do
                                        local cat = entry.category
                                        local item = entry.item
                                        MySQL.insert(
                                            'INSERT INTO battle_pass_items (battle_pass_id, category, itemTexture, itemTextureDict, selectedBackgroundTexture, selectedBackgroundTextureDict, label, description, `rank`, owned, rewards) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                            { 
                                                passId, 
                                                cat, 
                                                item.itemTexture, 
                                                item.itemTextureDict,  
                                                item.selectedBackgroundTexture, 
                                                item.selectedBackgroundTextureDict, 
                                                item.label, 
                                                item.description, 
                                                item.rank, 
                                                item.owned and 1 or 0,
                                                item.rewards and json.encode(item.rewards) or nil
                                            },
                                            function(itemInsertId)
                                                processedItems = processedItems + 1
                                                if processedItems == totalItems then
                                                    TriggerClientEvent('battlepass:updateResult', src, { success = true })
                                                    TriggerEvent('battlepass:refreshCache')
                                                end
                                            end
                                        )
                                    end
                                end
                            end)
                        else
                            TriggerClientEvent('battlepass:updateResult', src, { success = false, error = 'Battle pass details güncellemesi başarısız oldu.' })
                        end
                    end
                )
            else
                TriggerClientEvent('battlepass:updateResult', src, { success = false, error = 'Battle pass güncellemesi başarısız oldu.' })
            end
        end
    )
end)

-- @description: This event is triggered to save new battle pass data. It inserts the new battle pass data into the database and updates the cache.
-- @event: qadr_pass:saveData
-- @param: data - The new battle pass data.
RegisterNetEvent('qadr_pass:saveData')
AddEventHandler('qadr_pass:saveData', function(data)
    print(json.encode(data))

    local src = source
    -- Gelen JSON yapısını parçalayalım:
    local general    = data.general    -- passName, buyPromptText, seasonStart, seasonEnd, body (title, line1, line2)
    local visuals    = data.visuals    -- background, logo, progressPage
    local items      = data.items      -- premium ve free dizileri
    -- Diğer alanlar (seasonPassowned, infoScreen, progressPageData, playerData) ihtiyaç halinde ayrı tabloda saklanabilir

    -- Örnek ID üretimi: timestamp bazlı string (üretim şeklinizi geliştirebilirsiniz)
    local passId = tostring(os.time())
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
                    'INSERT INTO battle_pass_details (battle_pass_id, buy_prompt_text, background_dict, background_texture, background_gradient_dict, background_gradient_texture, logo_dict, logo_texture, body_title, body_line1, body_line2, progress_tile_texture_dict, progress_tile_texture, progress_rank_text_color,progress_large_texture_dict,progress_large_texture, progress_large_texture_alpha, progress_enabled, progress_tile_overlay_visible, progress_season_tool_tip_text) VALUES (?, ?,?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
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
                        visuals.progressPage.largeTextureTxd,
                        visuals.progressPage.largeTextureName,
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
                                    'INSERT INTO battle_pass_items (battle_pass_id, category, itemTexture, itemTextureDict, selectedBackgroundTexture, selectedBackgroundTextureDict, label, description, `rank`, owned, rewards) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                    { 
                                        passId, 
                                        cat, 
                                        item.itemTexture, 
                                        item.itemTextureDict,  
                                        item.selectedBackgroundTexture, 
                                        item.selectedBackgroundTextureDict, 
                                        item.label, 
                                        item.description, 
                                        item.rank, 
                                        item.owned and 1 or 0,
                                        item.rewards and json.encode(item.rewards) or nil  -- rewards alanı ekleniyor
                                    },
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
            progress_large_texture_dict = visuals.progressPage.largeTextureTxd,
            progress_large_texture = visuals.progressPage.largeTextureName,
            progress_large_texture_alpha = visuals.progressPage.largeTextureAlpha,
            progress_enabled = visuals.progressPage.enabled,
            progress_tile_overlay_visible = visuals.progressPage.tileOverlayVisible,
            progress_season_tool_tip_text = visuals.progressPage.seasonToolTipText
        },
        items = {}
    }
    if items.premium then
        for _, item in ipairs(items.premium) do
            item.category = 'premium'
            table.insert(newPassData.items, item)
            --table.insert(newPassData.items, { category = 'premium', item = item })
        end
        --newPassData.vipItem = items.premium
    end
    if items.free then
        for _, item in ipairs(items.free) do
            item.category = 'free'
            table.insert(newPassData.items, item)
            --table.insert(newPassData.items, { category = 'free', item = item })
        end
        --newPassData.rankItem = items.free
    end
    table.insert(battlepassCache, newPassData)
    if battlepassCache and #battlepassCache > 0 then
        TriggerClientEvent('qadr_pass:sendData', src, battlepassCache)
        TriggerClientEvent('qadr_pass:triggerClientforGettinBattlePass', -1)
    else
        TriggerClientEvent('qadr_pass:sendData', src, {})
    end
end)

-- @description: This event is triggered when a player attempts to collect a battle pass item. It checks if the player is eligible to collect the item and then gives the reward.
-- @event: qadr_ui:passItemCollect
-- @param: item - The item data.
RegisterNetEvent("qadr_ui:passItemCollect")
AddEventHandler("qadr_ui:passItemCollect", function(item)
    local src = source
    local Player = RedEM.GetPlayer(src)
    local userid = Player.identifier .. "_" .. Player.charid

    if not item or not item.itemId or not item.battle_pass_id then
        TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Geçersiz item bilgisi" })
        return
    end

    local activeBattlePass = getActiveBattlePassforUser(src)

    if not activeBattlePass or activeBattlePass.info.id ~= item.battle_pass_id then
        TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Aktif battle pass bulunamadı" })
        return
    end

    local userData = activeBattlePass.user

    if not userData then
        TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Oyuncu verisi bulunamadı" })
        return
    end

    -- Item verisini bulalım
    local itemData = nil
    for _, itm in ipairs(activeBattlePass.items) do
        if tonumber(itm.item_id) == tonumber(item.itemId) then
            itemData = itm
            break
        end
    end

    if not itemData then
        TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Item bulunamadı" })
        return
    end

    -- Oyuncu item'ı daha önce aldı mı kontrol edelim
    MySQL.query('SELECT * FROM battle_pass_user_items WHERE user_id = ? AND battle_pass_id = ? AND item_id = ?', 
    { userid, item.battle_pass_id, item.itemId }, function(result)
        if result and #result > 0 then
            TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Bu ödülü zaten aldınız." })
            return
        end

        -- Oyuncunun rank kontrolü
        if userData.rank < itemData.rank then
            TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Yeterli rank'a ulaşmadınız." })
            return
        end

        -- Premium ise premium kontrolü
        print(itemData.category, userData.seasonPassOwned)
        if itemData.category == "premium" and userData.seasonPassOwned ~= true then
            TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Bu ödül için Premium Battle Pass gerekiyor." })
            return
        end

        -- Her şey uygunsa ödülü verelim
        if itemData.rewards then
            for _, reward in ipairs(itemData.rewards) do
                if reward.type == "item" then
                    local ItemData = data.getItem(src, reward.name)
                    if ItemData then
                        ItemData.AddItem(reward.amount)
                    end
                elseif reward.type == "currency" then
                    Player.AddMoney(reward.amount)
                end
            end
        end

        -- Ödülü aldığını veritabanına kaydedelim
        MySQL.insert(
            "INSERT INTO battle_pass_user_items (user_id, battle_pass_id, item_id) VALUES (?, ?, ?)",
            { userid, item.battle_pass_id, item.itemId },
            function(insertId)
                if insertId then
                    -- Cache'i de güncelleyelim
                    table.insert(activeBattlePass.userItems, {
                        user_id = userid,
                        battle_pass_id = item.battle_pass_id,
                        item_id = item.itemId,
                        acquired_date = os.date("%Y-%m-%d %H:%M:%S")
                    })

                    TriggerClientEvent("qadr_ui_seasonpass:claimItem", src, item)
                    TriggerClientEvent("qadr_pass:collectResult", src, { success = true })
                else
                    TriggerClientEvent("qadr_pass:collectResult", src, { success = false, error = "Ödül kaydedilirken hata oluştu." })
                end
            end
        )
    end)
end)

-- @description: This event is triggered to get the active battle pass data for a player. It then sends the data to the client.
-- @event: qadr_pass:getActiveBattlePass
RegisterNetEvent('qadr_pass:getActiveBattlePass')
AddEventHandler('qadr_pass:getActiveBattlePass', function()
    local src = source
    if src ~= 0 then
        TriggerClientEvent('qadr_pass:activeData', src, getActiveBattlePassforUser(src))
    end
end)

-- @description: This event is triggered to delete a battle pass. It deletes the battle pass data from the database and updates the cache.
-- @event: qadr_pass:deleteBattlePass
-- @param: passId - The ID of the battle pass to delete.
RegisterNetEvent('qadr_pass:deleteBattlePass')
AddEventHandler('qadr_pass:deleteBattlePass', function(passId)
    local src = source
    if not passId then
        TriggerClientEvent('battlepass:deleteResult', src, { success = false, error = "Geçersiz battle pass id" })
        return
    end
    -- battle_pass_items tablosundan ilgili kayıtları siliyoruz
    MySQL.update('DELETE FROM battle_pass_items WHERE battle_pass_id = ?', { passId }, function(affectedItems)
        -- battle_pass_details tablosundan silme işlemi
        MySQL.update('DELETE FROM battle_pass_details WHERE battle_pass_id = ?', { passId }, function(affectedDetails)
            -- battle_passes tablosundan silme işlemi
            MySQL.update('DELETE FROM battle_passes WHERE id = ?', { passId }, function(affectedPass)
                if affectedPass > 0 then
                    local wasActive = false
                    -- getActiveBattlePassforUser
                    local activepass = getActiveBattlePassforUser()
                    -- Cache güncellemesi: silinen pass cache'den de çıkarılıyor
                    for i, bp in ipairs(battlepassCache or {}) do
                        if bp.info.id == tostring(passId) then
                            table.remove(battlepassCache, i)
                            
                            if bp.info.id == activepass.info.id then
                                wasActive = true
                            end
                            break
                        end
                    end
                    TriggerClientEvent('battlepass:deleteResult', src, { success = true })
                    -- Eğer silinen pass aktif pass ise tüm client'lara boş pass bilgisi gönderiyoruz
                    if wasActive then
                        TriggerClientEvent("qadr_pass:activeData", -1, nil)
                    end
                else
                    TriggerClientEvent('battlepass:deleteResult', src, { success = false, error = "Battle pass bulunamadı" })
                end
            end)
        end)
    end)
end)

-- @description: This event is triggered when a player loads into the game. It creates a battle pass user record if it doesn't exist and sends the active battle pass data to the client.
-- @event: redemrp:playerLoaded
-- @param: source - The player's source.
-- @param: user - The player's user data.
AddEventHandler("redemrp:playerLoaded",function(source, user)
    local src = source
    Wait(500)
    createBattlePassUserIfNotExists(src)
    TriggerClientEvent('qadr_pass:activeData', src, getActiveBattlePassforUser(src))
end)

-- @description This event is triggered to add XP to a player's battle pass.
-- @event qadr_pass:addXP
-- @param earnedXP number The amount of XP to add.
RegisterNetEvent('qadr_pass:addXP')
AddEventHandler('qadr_pass:addXP', function(earnedXP)
    local src = source
    -- güvenlik kontrolü
    if type(earnedXP) ~= "number" or earnedXP <= 0 then
        print("Geçersiz XP değeri geldi.")
        return
    end
    addPlayerPassXP(src, earnedXP)
end)

RegisterNetEvent('qadr_pass:addSeasonPass')
AddEventHandler('qadr_pass:addSeasonPass', function()
    local src = source
    addPlayerSeasonPass(src)
end)

-- @param source number The source of the player.
local function addPlayerSeasonPass(source)
    local Player = RedEM.GetPlayer(source)
    if not Player then return end

    local userid = Player.identifier .. "_" .. Player.charid
    local activePass = getActiveBattlePassforUser(source)

    if not activePass or not activePass.user then
        print("Aktif pass veya kullanıcı bulunamadı.")
        return
    end

    local userPassData = activePass.user
    if userPassData.seasonPassOwned == 1 then
        print("Kullanıcı zaten season pass'e sahip.")
        return
    end

    -- Güncellemeyi önce veritabanına kaydedelim
    MySQL.update('UPDATE battle_pass_users SET seasonPassOwned = ? WHERE user_id = ? AND battle_pass_id = ?', {
        1,
        userid,
        activePass.info.id
    }, function(rowsAffected, error)
        if error then
            print("Season Pass güncelleme hatası:", error)
        elseif rowsAffected > 0 then
            -- Cache'i de güncelle
            for _, bp in ipairs(battlepassCache) do
                if bp.info.id == activePass.info.id then
                    if bp.users and bp.users[userid] then
                        bp.users[userid].seasonPassOwned = 1
                    end
                    break
                end
            end

            -- Kullanıcıya bilgi gönder (client event)
            TriggerClientEvent('qadr_pass:passPurchase', source, {
                seasonPassOwned = 1
            })
        end
    end)
end

RegisterCommand("addSeasonPass", function(source, args, rawCommand)
    local src = source
    addPlayerSeasonPass(src)
end)
RegisterCommand("addXP", function(source, args, rawCommand)
    local src = source
    local earnedXP = tonumber(args[1]) or 1
    addPlayerPassXP(src, earnedXP)
end)
RegisterCommand("setrank", function(source, args, rawCommand)
    local src = source
    local rank = tonumber(args[1]) or 1
    setPlayerPassRank(src, rank)
end)

-- @param source number The source of the player.
-- @param newRank number The new rank to set for the player.
function setPlayerPassRank(source, newRank)
    local Player = RedEM.GetPlayer(source)
    if not Player then return end

    local userid = Player.identifier .. "_" .. Player.charid
    local activePass = getActiveBattlePassforUser(source)

    if not activePass or not activePass.user then
        print("Aktif pass veya kullanıcı bulunamadı.")
        return
    end

    local userPassData = activePass.user
    local currentXP = userPassData.xp or 0
    local currentRank = userPassData.rank or 0
    local xpRequired = userPassData.xpmax or 100

    -- Yeni rank'ı ayarlayalım
    local newRank = math.max(0, newRank) -- Rank 0'dan küçük olamaz
    local newXP = currentXP
    local newXpRequired = xpRequired
    if newRank > 0 then
        newXpRequired = newXpRequired + (newRank-1) * 100
    end
    -- Güncellemeyi önce veritabanına kaydedelim
    MySQL.update('UPDATE battle_pass_users SET `rank` = ?, xp = ?, xpmax = ? WHERE user_id = ? AND battle_pass_id = ?', {
        newRank,
        newXP,
        newXpRequired,
        userid,
        activePass.info.id
    }, function(rowsAffected, error)
        if error then
            print("Rank güncelleme hatası:", error)
        elseif rowsAffected > 0 then
            -- Cache'i de güncelle
            for _, bp in ipairs(battlepassCache) do
                if bp.info.id == activePass.info.id then
                    if bp.users and bp.users[userid] then
                        bp.users[userid].rank = newRank
                        bp.users[userid].xp = newXP
                        bp.users[userid].xpmax = newXpRequired
                    end
                    break
                end
            end

            -- Kullanıcıya bilgi gönder (client event)
            TriggerClientEvent('qadr_pass:updateXP', source, {
                xp = newXP,
                rank = newRank,
                xpmax = newXpRequired
            })
        end
    end)
end

    

-- @description This command is used to get the battle pass cache.
-- @command getCache
RegisterCommand("getCache", function(source, args, rawCommand)
    local src = source
    if src == 0 then
        print(json.encode(battlepassCache))
    end
end)