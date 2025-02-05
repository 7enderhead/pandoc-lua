-- auto small caps

local text = require 'text'

function Str(elem)
  -- Check if the string starts with a tilde
  if elem.text:sub(1, 1) == "~" then
    -- Remove the tilde and return the rest of the string as is
    return pandoc.Str(elem.text:sub(2))
  end
  
  -- Check if the string is all uppercase and at least 3 characters long
  if text.upper(elem.text) == elem.text and #elem.text >= 2 then
    -- Convert to lowercase and smallcaps syntax
    elem.text = text.lower(elem.text)
    return pandoc.SmallCaps(elem)
  else
    return elem
  end
end