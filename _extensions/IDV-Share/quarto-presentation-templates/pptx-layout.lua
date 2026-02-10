local columns = {}
local boxes = {}
local captions = {}
local column_counter = 0
local box_counter = 0
local caption_counter = 0

local function truthy(value)
  if value == nil then
    return false
  end
  if type(value) == "boolean" then
    return value
  end
  local text = pandoc.utils.stringify(value):lower()
  return text == "true" or text == "1" or text == "yes" or text == "on"
end

local function debug_enabled()
  if PANDOC_STATE and PANDOC_STATE.verbosity ~= nil then
    local level = tostring(PANDOC_STATE.verbosity):upper()
    if level == "DEBUG" then
      return true
    end
  end

  local env = os.getenv("PPTX_LAYOUT_DEBUG")
  if env and env ~= "" then
    return truthy(env)
  end
  if PANDOC_STATE and PANDOC_STATE.meta then
    return truthy(PANDOC_STATE.meta["pptx-layout-debug"])
  end
  return false
end

local function debug(msg)
  if debug_enabled() then
    io.stderr:write("[pptx-layout] " .. msg .. "\n")
  end
end

local function has_class(el, class)
  for _, c in ipairs(el.classes) do
    if c == class then
      return true
    end
  end
  return false
end

local function stringify_meta(meta_value)
  if meta_value == nil then
    return ""
  end
  return pandoc.utils.stringify(meta_value)
end

local function get_meta_value(doc, key)
  local value = stringify_meta(doc.meta[key])
  if value ~= "" then
    return value
  end

  local format_meta = doc.meta["format"]
  if type(format_meta) == "table" then
    local pptx_meta = format_meta["quarto-presentation-templates-pptx"] or format_meta["pptx"]
    if type(pptx_meta) == "table" then
      value = stringify_meta(pptx_meta[key])
      if value ~= "" then
        return value
      end
    end
  end

  return ""
end

local function get_attr_value(attrs, names)
  if attrs == nil then
    return ""
  end
  for _, name in ipairs(names) do
    local value = attrs[name]
    if value ~= nil and value ~= "" then
      return value
    end
  end
  return ""
end

local function caption_has_marker(caption)
  if caption == nil then
    return false
  end
  local text = pandoc.utils.stringify(caption)
  return text:find("CAPTION::") ~= nil
end

local function append_marker_to_caption(image, marker)
  if image.caption == nil then
    return false
  end

  if type(image.caption) == "table" and image.caption.long ~= nil then
    local blocks = image.caption.long
    if #blocks == 0 then
      table.insert(blocks, pandoc.Para({ pandoc.Str(marker) }))
    else
      local last = blocks[#blocks]
      if last.t == "Para" or last.t == "Plain" then
        table.insert(last.content, pandoc.Space())
        table.insert(last.content, pandoc.Str(marker))
      else
        table.insert(blocks, pandoc.Para({ pandoc.Str(marker) }))
      end
    end
    image.caption.long = blocks
    return true
  end

  if type(image.caption) == "table" then
    if #image.caption == 0 then
      return false
    end
    table.insert(image.caption, pandoc.Space())
    table.insert(image.caption, pandoc.Str(marker))
    return true
  end

  return false
end

local function parse_style(style)
  local styles = {}
  if style == nil or style == "" then
    return styles
  end
  for key, value in string.gmatch(style, "([%w-]+)%s*:%s*([^;]+)") do
    styles[string.lower(key)] = (value:gsub("^%s+", ""):gsub("%s+$", ""))
  end
  return styles
end

local function inject_marker(blocks, marker)
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      table.insert(block.content, 1, pandoc.Space())
      table.insert(block.content, 1, pandoc.Str(marker))
      return
    end
  end

  table.insert(blocks, 1, pandoc.Para({ pandoc.Str(marker) }))
end

local function append_marker(blocks, marker)
  for i = #blocks, 1, -1 do
    local block = blocks[i]
    if block.t == "Para" or block.t == "Plain" then
      table.insert(block.content, pandoc.Space())
      table.insert(block.content, pandoc.Str(marker))
      return
    end
  end

  table.insert(blocks, pandoc.Para({ pandoc.Str(marker) }))
end

function Div(el)
  if has_class(el, "column") then
    column_counter = column_counter + 1
    local id = el.identifier
    if id == nil or id == "" then
      id = "column-" .. tostring(column_counter)
    end

    local style = el.attributes["style"] or ""
    local styles = parse_style(style)
    local width = el.attributes["width"] or el.attributes["data-width"] or ""
    if width == "" then
      width = styles["width"] or ""
    end
    local valign = el.attributes["valign"] or el.attributes["vertical-align"] or styles["vertical-align"] or ""

    local marker = "COLUMN::" .. id
    inject_marker(el.content, marker)

    debug("column id=" .. id .. " width=" .. (width ~= "" and width or "<auto>") .. " valign=" .. (valign ~= "" and valign or "<auto>"))

    table.insert(columns, {
      id = id,
      width = width,
      valign = valign
    })

    return el
  end

  if has_class(el, "pptx-box") or has_class(el, "ppt-box") then
    box_counter = box_counter + 1
    local id = el.identifier
    if id == nil or id == "" then
      id = "box-" .. tostring(box_counter)
    end

    local width = el.attributes["width"] or el.attributes["data-width"] or ""
    local height = el.attributes["height"] or el.attributes["data-height"] or ""
    local pos_x = el.attributes["x"] or el.attributes["left"] or el.attributes["data-x"] or el.attributes["data-left"] or ""
    local pos_y = el.attributes["y"] or el.attributes["top"] or el.attributes["data-y"] or el.attributes["data-top"] or ""
    local style = el.attributes["style"] or ""
    local styles = parse_style(style)
    local valign = el.attributes["valign"] or el.attributes["vertical-align"] or styles["vertical-align"] or ""

    local marker = "BOX::" .. id
    inject_marker(el.content, marker)
    append_marker(el.content, "BOXEND::" .. id)

    debug("box id=" .. id .. " width=" .. (width ~= "" and width or "<auto>") .. " height=" .. (height ~= "" and height or "<auto>") .. " x=" .. (pos_x ~= "" and pos_x or "<auto>") .. " y=" .. (pos_y ~= "" and pos_y or "<auto>") .. " valign=" .. (valign ~= "" and valign or "<auto>"))

    table.insert(boxes, {
      id = id,
      width = width,
      height = height,
      x = pos_x,
      y = pos_y,
      valign = valign
    })

    return el
  end

  return nil
end

function Image(el)
  if el.caption == nil then
    return nil
  end
  if caption_has_marker(el.caption) then
    return nil
  end

  local has_caption = pandoc.utils.stringify(el.caption)
  if has_caption == nil or has_caption == "" then
    return nil
  end

  caption_counter = caption_counter + 1
  local id = el.identifier
  if id == nil or id == "" then
    id = "caption-" .. tostring(caption_counter)
  end

  local marker = "CAPTION::" .. id
  local ok = append_marker_to_caption(el, marker)
  if not ok then
    return nil
  end

  local size = get_attr_value(el.attributes, {
    "cap-size",
    "caption-size",
    "fig-caption-size",
    "fig-cap-size"
  })
  local dx = get_attr_value(el.attributes, {
    "cap-dx",
    "caption-dx",
    "fig-caption-dx"
  })
  local dy = get_attr_value(el.attributes, {
    "cap-dy",
    "caption-dy",
    "fig-caption-dy"
  })

  table.insert(captions, {
    id = id,
    size = size,
    dx = dx,
    dy = dy
  })

  debug("caption id=" .. id .. " size=" .. (size ~= "" and size or "<auto>") .. " dx=" .. (dx ~= "" and dx or "<auto>") .. " dy=" .. (dy ~= "" and dy or "<auto>"))

  return el
end

function Pandoc(doc)
  local footer = get_meta_value(doc, "footer")
  local location = get_meta_value(doc, "location")
  local caption_size = get_meta_value(doc, "fig-caption-size")
  if caption_size == "" then
    caption_size = get_meta_value(doc, "fig-cap-size")
  end
  local caption_dx = get_meta_value(doc, "fig-caption-dx")
  local caption_dy = get_meta_value(doc, "fig-caption-dy")

  if #columns == 0 and #boxes == 0 and #captions == 0 and footer == "" and location == "" and caption_size == "" and caption_dx == "" and caption_dy == "" then
    return doc
  end

  local output = stringify_meta(doc.meta["pptx-layout-json"])
  if output == "" then
    output = "pptx-layout.json"
  end

  local payload = {
    columns = columns,
    boxes = boxes,
    captions = captions,
    caption_defaults = {
      size = caption_size,
      dx = caption_dx,
      dy = caption_dy
    },
    footer = footer,
    location = location
  }

  local ok, encoded = pcall(pandoc.json.encode, payload)
  if not ok then
    return doc
  end

  local file = io.open(output, "w")
  if file ~= nil then
    file:write(encoded)
    file:close()
    debug("wrote layout payload to " .. output)
  end

  return doc
end
