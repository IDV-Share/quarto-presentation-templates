-- custom-font-size.lua
-- Reliable local font size reduction for PPTX using OpenXML

local function is_pptx()
  return FORMAT:match("pptx")
end

-- PowerPoint font size units: 1/100 pt
local SIZES = {
  LARGE = 2800,       -- 28 pt
  Large = 2400,       -- 24 pt
  large = 2200,       -- 22 pt
  normal = 2000,      -- 20 pt
  small = 1800,       -- 18 pt
  Small = 1600,       -- 16 pt
  SMALL = 1400,       -- 14 pt
  tiny = 1200,        -- 12 pt
  Tiny = 1000,        -- 10 pt
  TINY = 800,         -- 8 pt
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