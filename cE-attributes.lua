-- Define replacements based on output format
local replacements = {
    ["{{check}}"] = {
      all = "✔"
    }
  }

-- Function to replace commands based on the output format
function Str(el)
    local fmt = PANDOC_FORMAT -- Get the current output format
    local replacement = replacements[el.text] -- Get the replacement entry for the text
  
    if replacement then
      -- Check for "all" substitution first
      if replacement.all then
        return pandoc.Str(replacement.all) -- Replace with corresponding text for all formats
      end
  
      -- If specific format substitution exists, use it
      if replacement[fmt] then
        return pandoc.Str(replacement[fmt]) -- Replace with corresponding text for the specific format
      end
    end
    
    -- If no replacement is found or format is not specified, return original text
    return el 
end

function Span(el)
    -- Check if the span has the class "name"
    if el.classes:includes("name") then
      local content = pandoc.utils.stringify(el.content)
  
      if FORMAT == "html" then
        -- For HTML output, wrap in a <strong> tag
        return pandoc.RawInline('html', '<strong>' .. content .. '</strong>')
        
      elseif FORMAT == "latex" then
        -- For LaTeX output, wrap in \textbf{}
        return pandoc.RawInline('latex', '\\textbf{\\[' .. content .. '\\]}')
        
      elseif FORMAT == "typst" then
        -- For Typst output, wrap in \bold{}
        return pandoc.RawInline('typst', '#text(weight: \"bold\")[\\[' .. content .. '\\]]')
        
      else
        -- If format is not recognized, return the original element unchanged
        return el
      end
    end
  
    -- If no matching class, return the original element unchanged
    return el
  end