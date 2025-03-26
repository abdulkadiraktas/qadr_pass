
qadr_lang = qadr_pass_settings.translations[qadr_pass_settings.defaultlang or "en"]
function getlang(...)
    local args = {...}
    local key = table.remove(args, 1)
    local text

    if type(qadr_lang[key]) == "table" then
        local category = key
        key = table.remove(args, 1)
        text = qadr_lang[category][key] or string.format("Missing translation for %s from %s", key, category)
    else
        text = qadr_lang[key] or string.format("Missing translation for %s", key)
    end

    return #args > 0 and string.format(text, table.unpack(args)) or text
end