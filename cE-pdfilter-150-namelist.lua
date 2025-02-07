-- Function to parse name and generate abbreviation
local function parseName(name)
  local first, middle, last, company, abbr
  
  -- Extract company name if present
  name, company = name:match("^(.-)%s*(%(.+%))$") or name, nil
  
  if name:find(",") then
      -- Format: Last, First Middle
      last, rest = name:match("^%s*(%S+)%s*,%s*(.+)")
      first, middle = rest:match("^(%S+)%s*(.*)$")
  else
      -- Format: First Middle Last or First Last
      local parts = {}
      for part in name:gmatch("%S+") do
          table.insert(parts, part)
      end
      if #parts == 3 then
          first, middle, last = parts[1], parts[2], parts[3]
      else
          first, last = parts[1], parts[#parts]
      end
  end
  abbr = first:sub(1,1):upper() .. last:sub(1,1):upper()
  return first, middle, last, company, abbr
end

-- Function to generate unique abbreviations
local function generateUniqueAbbreviation(abbr, used)
  local suffix = 1
  local original_abbr = abbr
  while used[abbr] do
      suffix = suffix + 1
      abbr = original_abbr .. suffix
  end
  used[abbr] = true
  return abbr
end

-- Function to format name consistently
local function formatName(first, middle, last, company)
  local name
  if middle and middle ~= "" then
      name = string.format("%s %s %s", first, middle, last)
  else
      name = string.format("%s %s", first, last)
  end
  if company then
      name = name .. " " .. company
  end
  return name
end

function Div(el)
  if el.identifier == "name-list" then
      local names = {}
      local used_abbrs = {}
      
      -- Extract names and generate abbreviations
      for _, block in ipairs(el.content) do
          if block.t == "Para" then
              local text = block.content and pandoc.utils.stringify(block.content) or ""
              for line in text:gmatch("[^\n]+") do
                  local name = line:match("^%*?%s*(.+)$")
                  if name then
                      local first, middle, last, company, abbr = parseName(name)
                      local formatted_name = formatName(first, middle, last, company)
                      local full_name = formatted_name
                      if line:match("^%*") then
                          abbr = generateUniqueAbbreviation(abbr, used_abbrs)
                          full_name = formatted_name .. " [" .. abbr .. "]{.name}"
                      end
                      table.insert(names, {
                          full = full_name,
                          last = last:lower(),
                          first = first:lower()
                      })
                  end
              end
          end
      end
      
      -- Sort names by last name, then first name
      table.sort(names, function(a, b)
          if a.last == b.last then
              return a.first < b.first
          end
          return a.last < b.last
      end)
      
      -- Split into two columns
      local mid = math.ceil(#names / 2)
      local col1, col2 = {}, {}
      for i = 1, mid do table.insert(col1, names[i].full) end
      for i = mid+1, #names do table.insert(col2, names[i].full) end
      
      -- Create two-column layout
      return {
          pandoc.Div({
              pandoc.Div(pandoc.BulletList(col1), {class = "column"}),
              pandoc.Div(pandoc.BulletList(col2), {class = "column"})
          }, {class = "two-column"})
      }
  end
end