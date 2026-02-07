-- reduce-font.lua
-- Reliable local font size reduction for PPTX using OpenXML

local function is_pptx()
  return FORMAT:match("pptx")
end

-- PowerPoint font size units: 1/100 pt
local SIZES = {
  small = 1800,       -- 18 pt
  ["very-small"] = 1400  -- 14 pt
}

function Span(el)
  if not is_pptx() then
    return nil
  end

  for cls, size in pairs(SIZES) do
    if el.classes:includes(cls) then
      local text = pandoc.utils.stringify(el.content)

      local xml = string.format(
        '<a:r><a:rPr sz="%d"/><a:t>%s</a:t></a:r>',
        size,
        text
      )

      return pandoc.RawInline(
        "openxml",
        xml
      )
    end
  end
end