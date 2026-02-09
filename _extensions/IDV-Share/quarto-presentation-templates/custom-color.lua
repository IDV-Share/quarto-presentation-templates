-- Apply inline text color using style="color: ..."
-- Works for pptx, html; safely ignored elsewhere
-- Usage: `This is [red]{style="color: green"} text.`

local function parse_color(style)
  if not style then return nil end
  local c = style:match("color%s*:%s*([^;]+)")
  if not c then return nil end
  c = c:gsub("%s+", "")
  if c:match("^#") then
    c = c:sub(2)
  end
  return c:upper()
end

function Span(el)
  if FORMAT ~= "pptx" then
    return nil
  end

  local style = el.attributes["style"]
  local color = parse_color(style)
  if not color then
    return nil
  end

  local text = pandoc.utils.stringify(el.content)

  local openxml = string.format([[
<a:r>
  <a:rPr>
    <a:solidFill>
      <a:srgbClr val="%s"/>
    </a:solidFill>
  </a:rPr>
  <a:t>%s</a:t>
</a:r>
]], color, text)

  return pandoc.RawInline("openxml", openxml)
end