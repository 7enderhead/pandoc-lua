-- Define replacements based on output format
local replacements = {
    ["{{check}}"] = {
      all = "✔"
    },
    [",/"] = {
      all = "✔"
    },
    ["->"] = {
      all = "→"
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
    
  local content = pandoc.utils.stringify(el.content)
  
  -- Check if the span has the class "name"
  if el.classes:includes("name") then
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

  -- Check if the span has the class "name"
  if el.classes:includes("new") then
    if FORMAT == "html" then
      -- For HTML output, wrap in a <strong> tag
      return pandoc.RawInline('html', '<strong>' .. content .. '</strong>')
      
    elseif FORMAT == "latex" then
      -- For LaTeX output, wrap in \textbf{}
      return pandoc.RawInline('latex', '\\textbf{\\' .. content .. '\\}')
      
    elseif FORMAT == "typst" then
      -- For Typst output, wrap in \bold{}
      return pandoc.RawInline('typst', '#text(weight: \"bold\")[' .. content .. ']')
      
    else
      -- If format is not recognized, return the original element unchanged
      return el
    end
  end
    
  if el.classes:includes("docref") then
    if FORMAT == "html" then
      -- For HTML output, wrap in a <strong> tag
      return pandoc.RawInline('html', '<em>\\"' .. content .. '\\"</em>')
      
    elseif FORMAT == "latex" then
      -- For LaTeX output, wrap in \textbf{}
      return pandoc.RawInline('latex', '\\textit{\\"' .. content .. '\\"}')
      
    elseif FORMAT == "typst" then
      -- For Typst output, wrap in \bold{}
      return pandoc.RawInline('typst', '#text(style: \"italic\")[\\"' .. content .. '\\"]')
      
    else
      -- If format is not recognized, return the original element unchanged
      return el
    end
  end
  
  -- Tracking
  
  if el.classes:includes("added") then
    if FORMAT == "html" then
      -- For HTML output, wrap in a <strong> tag
      return pandoc.RawInline('html', '<color:blue>' .. content .. '</color>')
         
    elseif FORMAT == "typst" then
      -- For Typst output, wrap in \bold{}
      return pandoc.RawInline("typst", "#underline(text(fill: blue)[" .. content .. "])")
      
    else
      -- If format is not recognized, return the original element unchanged
      return el
    end
  end

  if el.classes:includes("deleted") then
    if FORMAT == "html" then
      -- For HTML output, wrap in a <strong> tag
      return pandoc.RawInline('html', '<color:blue>' .. content .. '</color>')
         
    elseif FORMAT == "typst" then
      -- For Typst output, wrap in \bold{}
      return pandoc.RawInline("typst", "#strike(text(fill: red)[" .. content .. "])")
      
    else
      -- If format is not recognized, return the original element unchanged
      return el
    end
  end

  -- produce link with identical target and text (without having to repeat it in the markdown input)
  if el.classes:includes("link") then
    return pandoc.Link(content, content)
  end

  -- If no matching class, return the original element unchanged
  return el
end

function Link(el)
  
  return el
end