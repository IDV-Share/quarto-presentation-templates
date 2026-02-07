-- emphasis-colors.lua
-- Apply custom colors to bold and italic text in PPTX

local function is_pptx()
  return FORMAT:match("pptx")
end

-- PowerPoint colors (hex RGB, no #)
local COLORS = {
  bold =  "E16F00" ,
  italic = "1E90FF"
}

-- Convert inline content to a colored OpenXML run
local function colored_run(text, color, bold, italic)
  local props = {}

  if bold then table.insert(props, 'b="1"') end
  if italic then table.insert(props, 'i="1"') end

  local rPr = string.format(
    '<a:rPr %s><a:solidFill><a:srgbClr val="%s"/></a:solidFill></a:rPr>',
    table.concat(props, " "),
    color
  )

  return pandoc.RawInline(
    "openxml",
    string.format(
      '<a:r>%s<a:t>%s</a:t></a:r>',
      rPr,
      text
    )
  )
end

function Strong(el)
  if not is_pptx() then
    return nil
  end

  local text = pandoc.utils.stringify(el.content)
  return colored_run(text, COLORS.bold, true, false)
end

function Emph(el)
  if not is_pptx() then
    return nil
  end

  local text = pandoc.utils.stringify(el.content)
  return colored_run(text, COLORS.italic, false, true)
end