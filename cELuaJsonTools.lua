local cELuaJsonTools = {}

local json = require "json"
require "cELuaTools"

function createTable(jsonData)
    local luaTable = {}
    for key, value in pairs(jsonData) do
        if type(value) == "table" then
            luaTable[key] = createTable(value)
        else
            luaTable[key] = value
        end
    end
    return luaTable
end

function dataFromJsonFile(filePath)
    local jsonString = readFile(filePath)
    local parsed = json.decode(jsonString)
    
    -- Create objects from parsed data
    local objects = {}
    for _, data in ipairs(parsed) do
        table.insert(objects, createTable(data))
    end

    return objects
end

return cELuaJsonTools