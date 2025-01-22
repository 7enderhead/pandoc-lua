local cELuaTools = {}

function orderedKeys(tbl)
  local orderedKeys = {}
  for key,_ in pairs(tbl) do
    table.insert(orderedKeys, key)
  end
  table.sort(orderedKeys)
  return orderedKeys
end

-- Order table by keys
function orderedPairs(tbl)
    local orderedKeys = orderedKeys(tbl)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if orderedKeys[i] == nil then return nil
        else
          key = orderedKeys[i]
          value = tbl[key] or "(no value found for key" .. key .. ")"
          return key, value
        end
    end
    return iter
end

function readFile(filename)
  local file = io.open(filename, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

function separatedObjectStrings(obj, keys, separator, defaultString)
  if obj == nil then
    return ""
  end

  if keys == nil then -- assume all keys
    keys = orderedKeys(obj)
  end
  
  if separator == nil then
    separator = ", "
  end

  if defaultString == nil then
    defaultString = "(-)"
  end
  
  local result = {}
  
  for _, key in ipairs(keys) do
    local value = obj[key]
    local stringRepresentation = defaultString
    if value ~= nil then
      if type(value) == "table" then
        stringRepresentation = "[" .. separatedObjectStrings(value) .. "]"
      else
        stringRepresentation = tostring(value)
      end
    end
    table.insert(result, stringRepresentation)
  end
  return table.concat(result, separator)
end

function allSeparatedObjectStrings(objs, keys, valueSeparator, objSeparator, defaultString)
  if objs == nil then
    return ""
  end

  if valueSeparator == nil then
    valueSeparator = ", "
  end

  if objSeparator == nil then
    objSeparator = "\n"
  end

  if defaultString == nil then
    defaultString = "(-)"
  end

  local result = {}
  for _, obj in ipairs(objs) do
    table.insert(result, separatedObjectStrings(obj, keys, valueSeparator, defaultString))
  end
  local concatResult = table.concat(result, objSeparator)
  return concatResult
end

return cELuaTools