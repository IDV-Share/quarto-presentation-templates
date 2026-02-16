local columns = {}
local boxes = {}
local captions = {}
local text_blocks = {}
local column_counter = 0
local box_counter = 0
local caption_counter = 0
local text_block_counter = 0
local LAYOUT_PREFIX = "LAYOUT::"
local HIDE_PREFIX = "HIDE::"
local TEXTBLOCK_PREFIX = "TEXTBLOCK::"
local TEXTBLOCK_END_PREFIX = "TEXTBLOCKEND::"
local POSTPROCESS_DISABLED = nil
local MARKER_PREFIXES = {
  "COLUMN::",
  "BOX::",
  "BOXEND::",
  "CAPTION::",
  "LAYOUT::",
  HIDE_PREFIX,
  TEXTBLOCK_PREFIX,
  TEXTBLOCK_END_PREFIX
}

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

local function get_meta_value_from(meta, key)
  if type(meta) ~= "table" then
    return ""
  end

  local value = stringify_meta(meta[key])
  if value ~= "" then
    return value
  end

  local format_meta = meta["format"]
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

local function get_meta_value(doc, key)
  return get_meta_value_from(doc.meta, key)
end

local function postprocess_disabled_from_meta(meta)
  local value = get_meta_value_from(meta, "disable-postprocess")
  if value == "" then
    value = get_meta_value_from(meta, "disable_postprocess")
  end
  return truthy(value)
end

local function postprocess_disabled_state()
  if POSTPROCESS_DISABLED ~= nil then
    return POSTPROCESS_DISABLED
  end
  if PANDOC_STATE == nil or PANDOC_STATE.meta == nil then
    POSTPROCESS_DISABLED = false
    return POSTPROCESS_DISABLED
  end
  POSTPROCESS_DISABLED = postprocess_disabled_from_meta(PANDOC_STATE.meta)
  return POSTPROCESS_DISABLED
end

local function starts_with(text, prefix)
  return text ~= nil and prefix ~= nil and text:sub(1, #prefix) == prefix
end

local function is_marker_token(text)
  for _, prefix in ipairs(MARKER_PREFIXES) do
    if starts_with(text, prefix) then
      return true
    end
  end
  return false
end

local function strip_marker_tokens(doc)
  return doc:walk({
    Str = function(el)
      if is_marker_token(el.text or "") then
        return {}
      end
      return nil
    end
  })
end

function Meta(meta)
  POSTPROCESS_DISABLED = postprocess_disabled_from_meta(meta)
  return meta
end

local function get_slide_level()
  if PANDOC_WRITER_OPTIONS and PANDOC_WRITER_OPTIONS.slide_level ~= nil then
    return tonumber(PANDOC_WRITER_OPTIONS.slide_level) or 2
  end
  return 2
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

local function append_marker_to_caption_value(caption, marker)
  if caption == nil then
    return caption, false
  end

  local function append_to_inlines(inlines)
    if inlines == nil then
      return false
    end
    if #inlines > 0 then
      table.insert(inlines, pandoc.Space())
      table.insert(inlines, pandoc.Str(marker))
      return true
    end
    return false
  end

  local function append_to_blocks(blocks)
    if blocks == nil then
      return false
    end
    for i = #blocks, 1, -1 do
      local block = blocks[i]
      if block.t == "Para" or block.t == "Plain" then
        table.insert(block.content, pandoc.Space())
        table.insert(block.content, pandoc.Str(marker))
        return true
      end
    end
    return false
  end

  local appended = false

  local ok_long_get, long_blocks = pcall(function()
    return caption.long
  end)
  if ok_long_get and long_blocks ~= nil then
    local blocks = long_blocks
    local ok = append_to_blocks(blocks)
    if not ok then
      local caption_text = pandoc.utils.stringify(caption)
      if caption_text ~= nil and caption_text ~= "" then
        blocks = {
          pandoc.Plain({
            pandoc.Str(caption_text),
            pandoc.Space(),
            pandoc.Str(marker)
          })
        }
        ok = true
      end
    end
    if not ok then
      return caption, false
    end
    local ok_long_set = pcall(function()
      caption.long = blocks
    end)
    if ok_long_set then
      appended = true
    end
  end

  local ok_short_get, short_inlines = pcall(function()
    return caption.short
  end)
  if ok_short_get and short_inlines ~= nil then
    local inlines = short_inlines
    local ok = append_to_inlines(inlines)
    if not ok then
      local short_text = pandoc.utils.stringify(short_inlines)
      if short_text ~= nil and short_text ~= "" then
        inlines = {
          pandoc.Str(short_text),
          pandoc.Space(),
          pandoc.Str(marker)
        }
        ok = true
      end
    end
    if ok then
      local ok_short_set = pcall(function()
        caption.short = inlines
      end)
      if ok_short_set then
        appended = true
      end
    end
  end

  if appended then
    return caption, true
  end

  if type(caption) == "table" then
    if #caption > 0 then
      table.insert(caption, pandoc.Space())
      table.insert(caption, pandoc.Str(marker))
      return caption, true
    end
    return caption, false
  end

  return caption, false
end

local function parse_style(style)
  local styles = {}
  if style == nil or style == "" then
    return styles
  end

  -- Robust CSS declaration parsing (handles spacing/newlines consistently).
  for decl in string.gmatch(tostring(style), "([^;]+)") do
    local key, value = string.match(decl, "^%s*([^:]+)%s*:%s*(.-)%s*$")
    if key ~= nil and value ~= nil and key ~= "" and value ~= "" then
      styles[string.lower(key)] = value
    end
  end
  return styles
end

local function inject_marker_into_blocks(blocks, marker)
  if blocks == nil then
    return false
  end

  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      table.insert(block.content, 1, pandoc.Space())
      table.insert(block.content, 1, pandoc.Str(marker))
      return true
    elseif block.t == "Div" or block.t == "BlockQuote" then
      if inject_marker_into_blocks(block.content, marker) then
        return true
      end
    elseif block.t == "BulletList" or block.t == "OrderedList" then
      for _, item in ipairs(block.content or {}) do
        if inject_marker_into_blocks(item, marker) then
          return true
        end
      end
    elseif block.t == "DefinitionList" then
      for _, item in ipairs(block.content or {}) do
        local defs = item[2] or {}
        for _, def_blocks in ipairs(defs) do
          if inject_marker_into_blocks(def_blocks, marker) then
            return true
          end
        end
      end
    end
  end

  return false
end

local function append_marker_into_blocks(blocks, marker)
  if blocks == nil then
    return false
  end

  for i = #blocks, 1, -1 do
    local block = blocks[i]
    if block.t == "Para" or block.t == "Plain" then
      table.insert(block.content, pandoc.Space())
      table.insert(block.content, pandoc.Str(marker))
      return true
    elseif block.t == "Div" or block.t == "BlockQuote" then
      if append_marker_into_blocks(block.content, marker) then
        return true
      end
    elseif block.t == "BulletList" or block.t == "OrderedList" then
      local items = block.content or {}
      for j = #items, 1, -1 do
        if append_marker_into_blocks(items[j], marker) then
          return true
        end
      end
    elseif block.t == "DefinitionList" then
      local defs_list = block.content or {}
      for j = #defs_list, 1, -1 do
        local item = defs_list[j]
        local defs = item[2] or {}
        for k = #defs, 1, -1 do
          if append_marker_into_blocks(defs[k], marker) then
            return true
          end
        end
      end
    end
  end

  return false
end

local function inject_marker(blocks, marker)
  if inject_marker_into_blocks(blocks, marker) then
    return
  end
  table.insert(blocks, 1, pandoc.Para({ pandoc.Str(marker) }))
end

local function append_marker(blocks, marker)
  if append_marker_into_blocks(blocks, marker) then
    return
  end
  table.insert(blocks, pandoc.Para({ pandoc.Str(marker) }))
end

local function append_marker_existing(blocks, marker)
  for i = #blocks, 1, -1 do
    local block = blocks[i]
    if block.t == "Para" or block.t == "Plain" then
      table.insert(block.content, pandoc.Space())
      table.insert(block.content, pandoc.Str(marker))
      return true
    end
  end
  return false
end

local function clean_font_family(value)
  if value == nil then
    return ""
  end
  local text = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
  text = text:gsub("^['\"]", ""):gsub("['\"]$", "")
  return text
end

local CLASS_FONT_SIZES_PT = {
  LARGE = 28,
  Large = 24,
  large = 22,
  normal = 20,
  small = 18,
  Small = 16,
  SMALL = 14,
  tiny = 12,
  Tiny = 10,
  TINY = 8
}

local function is_pptx()
  return FORMAT:match("pptx")
end

local function class_font_size_pt_from_classes(classes)
  if classes == nil then
    return nil
  end
  for _, class in ipairs(classes) do
    local mapped = CLASS_FONT_SIZES_PT[class]
    if mapped ~= nil then
      return mapped
    end
  end
  return nil
end

local function class_font_size_from_classes(classes)
  local size_pt = class_font_size_pt_from_classes(classes)
  if size_pt == nil then
    return ""
  end
  return tostring(size_pt) .. "pt"
end

local function xml_escape(text)
  if text == nil then
    return ""
  end
  local escaped = tostring(text)
  escaped = escaped:gsub("&", "&amp;")
  escaped = escaped:gsub("<", "&lt;")
  escaped = escaped:gsub(">", "&gt;")
  escaped = escaped:gsub("\"", "&quot;")
  escaped = escaped:gsub("'", "&apos;")
  return escaped
end

function Span(el)
  if not is_pptx() then
    return nil
  end
  local size_pt = class_font_size_pt_from_classes(el.classes)
  if size_pt == nil then
    return nil
  end
  local text = pandoc.utils.stringify(el.content)
  if text == nil or text == "" then
    return nil
  end
  local xml = string.format(
    '<a:r><a:rPr sz="%d"/><a:t>%s</a:t></a:r>',
    math.floor(size_pt * 100),
    xml_escape(text)
  )
  return pandoc.RawInline("openxml", xml)
end

local function font_size_from_classes(classes)
  local size = class_font_size_from_classes(classes)
  if size ~= "" then
    return size
  end
  return ""
end

local function header_has_layout_marker(header)
  local text = pandoc.utils.stringify(header.content or {})
  return text:find(LAYOUT_PREFIX, 1, true) ~= nil
end

local function header_has_hide_marker(header)
  local text = pandoc.utils.stringify(header.content or {})
  return text:find(HIDE_PREFIX, 1, true) ~= nil
end

local function inject_layout_marker_into_header(header, layout_name)
  if header == nil or layout_name == nil or layout_name == "" then
    return
  end
  if header_has_layout_marker(header) then
    return
  end

  local parts = {}
  for part in string.gmatch(layout_name, "%S+") do
    table.insert(parts, part)
  end
  if #parts == 0 then
    return
  end

  table.insert(header.content, pandoc.Space())
  table.insert(header.content, pandoc.Str(LAYOUT_PREFIX .. parts[1]))
  for i = 2, #parts do
    table.insert(header.content, pandoc.Space())
    table.insert(header.content, pandoc.Str(parts[i]))
  end
end

local function inject_hide_marker_into_header(header)
  if header == nil then
    return
  end
  if header_has_hide_marker(header) then
    return
  end
  table.insert(header.content, pandoc.Space())
  table.insert(header.content, pandoc.Str(HIDE_PREFIX .. "1"))
end

function Div(el)
  if postprocess_disabled_state() then
    return nil
  end

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
    local marker_ok = append_marker_existing(el.content, marker)
    if not marker_ok then
      debug("column id=" .. id .. " has no paragraph/plain block for marker injection; skipping marker.")
      return el
    end

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

  local style = el.attributes["style"] or ""
  local styles = parse_style(style)
  local font_size = get_attr_value(el.attributes, {
    "font-size",
    "text-size",
    "pptx-font-size"
  })
  if font_size == "" then
    font_size = styles["font-size"] or ""
  end
  if font_size == "" then
    font_size = font_size_from_classes(el.classes)
  end

  local font_style = get_attr_value(el.attributes, {
    "font-style",
    "text-style",
    "pptx-font-style"
  })
  if font_style == "" then
    font_style = styles["font-style"] or ""
  end

  local font_weight = get_attr_value(el.attributes, {
    "font-weight",
    "text-weight",
    "pptx-font-weight"
  })
  if font_weight == "" then
    font_weight = styles["font-weight"] or ""
  end

  local font_family = get_attr_value(el.attributes, {
    "font-family",
    "font-name",
    "font-type",
    "typeface",
    "pptx-font-family"
  })
  if font_family == "" then
    font_family = styles["font-family"] or ""
  end
  font_family = clean_font_family(font_family)

  if style ~= "" then
    debug(
      "div style parsed: size=" .. (font_size ~= "" and font_size or "<auto>")
        .. " style=" .. (font_style ~= "" and font_style or "<auto>")
        .. " weight=" .. (font_weight ~= "" and font_weight or "<auto>")
        .. " family=" .. (font_family ~= "" and font_family or "<auto>")
    )
  end

  if font_size == "" and font_style == "" and font_weight == "" and font_family == "" then
    return nil
  end

  text_block_counter = text_block_counter + 1
  local id = el.identifier
  if id == nil or id == "" then
    id = "textblock-" .. tostring(text_block_counter)
  end

  inject_marker(el.content, TEXTBLOCK_PREFIX .. id)
  append_marker(el.content, TEXTBLOCK_END_PREFIX .. id)

  table.insert(text_blocks, {
    id = id,
    size = font_size,
    style = font_style,
    weight = font_weight,
    family = font_family
  })

  debug(
    "text block id=" .. id
      .. " size=" .. (font_size ~= "" and font_size or "<auto>")
      .. " style=" .. (font_style ~= "" and font_style or "<auto>")
      .. " weight=" .. (font_weight ~= "" and font_weight or "<auto>")
      .. " family=" .. (font_family ~= "" and font_family or "<auto>")
  )

  return el

end

local function caption_entry_exists(id)
  if id == nil or id == "" then
    return false
  end
  for _, entry in ipairs(captions) do
    if entry.id == id then
      return true
    end
  end
  return false
end

local function element_identifier(el)
  if el == nil then
    return ""
  end
  local id = el.identifier
  if id ~= nil and id ~= "" then
    return id
  end
  if el.attr ~= nil and el.attr.identifier ~= nil and el.attr.identifier ~= "" then
    return el.attr.identifier
  end
  return ""
end

local function element_attributes(el)
  if el == nil then
    return {}
  end
  if el.attributes ~= nil then
    return el.attributes
  end
  if el.attr ~= nil and el.attr.attributes ~= nil then
    return el.attr.attributes
  end
  return {}
end

local function register_caption_marker(el, source_label)
  if el == nil then
    return false
  end
  if el.caption == nil then
    debug(source_label .. " caption skipped: no caption field")
    return false
  end
  if caption_has_marker(el.caption) then
    debug(source_label .. " caption skipped: marker already present")
    return false
  end

  local has_caption = pandoc.utils.stringify(el.caption)
  if has_caption == nil or has_caption == "" then
    debug(source_label .. " caption skipped: empty caption text")
    return false
  end

  local id = element_identifier(el)
  if id == nil or id == "" then
    caption_counter = caption_counter + 1
    id = "caption-" .. tostring(caption_counter)
  end

  local marker = "CAPTION::" .. id
  local updated_caption, ok = append_marker_to_caption_value(el.caption, marker)
  if not ok then
    debug(source_label .. " caption skipped: unable to append marker")
    return false
  end
  el.caption = updated_caption

  if not caption_entry_exists(id) then
    local attrs = element_attributes(el)
    local size = get_attr_value(attrs, {
      "cap-size",
      "caption-size",
      "fig-caption-size",
      "fig-cap-size"
    })
    local dx = get_attr_value(attrs, {
      "cap-dx",
      "caption-dx",
      "fig-caption-dx"
    })
    local dy = get_attr_value(attrs, {
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

    debug(source_label .. " caption id=" .. id .. " size=" .. (size ~= "" and size or "<auto>") .. " dx=" .. (dx ~= "" and dx or "<auto>") .. " dy=" .. (dy ~= "" and dy or "<auto>"))
  else
    debug(source_label .. " caption id=" .. id .. " already registered; marker injected only")
  end

  return true
end

local function walk_blocks_for_figure_captions(blocks, stats)
  if blocks == nil then
    return
  end
  for _, block in ipairs(blocks) do
    if block.t == "Figure" then
      if stats ~= nil then
        stats.figures = stats.figures + 1
      end
      register_caption_marker(block, "figure(scan)")
    end

    if block.t == "Div" or block.t == "BlockQuote" then
      if stats ~= nil and block.t == "Div" and has_class(block, "cell-output-display") then
        stats.cell_output_divs = stats.cell_output_divs + 1
      end
      walk_blocks_for_figure_captions(block.content, stats)
    elseif block.t == "BulletList" or block.t == "OrderedList" then
      for _, item in ipairs(block.content or {}) do
        walk_blocks_for_figure_captions(item, stats)
      end
    elseif block.t == "DefinitionList" then
      for _, item in ipairs(block.content or {}) do
        local defs = item[2] or {}
        for _, def_blocks in ipairs(defs) do
          walk_blocks_for_figure_captions(def_blocks, stats)
        end
      end
    end
  end
end

function Image(el)
  if postprocess_disabled_state() then
    return nil
  end

  register_caption_marker(el, "image")
  return el
end

function Figure(el)
  if postprocess_disabled_state() then
    return nil
  end

  register_caption_marker(el, "figure")
  return el
end

function Pandoc(doc)
  local disabled = postprocess_disabled_from_meta(doc.meta)
  POSTPROCESS_DISABLED = disabled
  if disabled then
    debug("postprocess disabled: layout and marker injection skipped.")
    return strip_marker_tokens(doc)
  end

  -- Fallback for executed-code figures nested in Div blocks when Figure callback
  -- is not dispatched by the surrounding filter pipeline.
  local scan_stats = { figures = 0, cell_output_divs = 0 }
  walk_blocks_for_figure_captions(doc.blocks, scan_stats)
  debug("figure scan stats: figures=" .. tostring(scan_stats.figures) .. " cell-output-divs=" .. tostring(scan_stats.cell_output_divs))

  local footer = get_meta_value(doc, "footer")
  local location = get_meta_value(doc, "location")
  local caption_size = get_meta_value(doc, "fig-caption-size")
  if caption_size == "" then
    caption_size = get_meta_value(doc, "fig-cap-size")
  end
  local caption_dx = get_meta_value(doc, "fig-caption-dx")
  local caption_dy = get_meta_value(doc, "fig-caption-dy")

  -- Force layout.
  local slide_level = get_slide_level()
  local current_header = nil

  -- Add explicit layout markers from header attributes so postprocess.py can
  -- force master layouts in PowerPoint even when pandoc/quarto cannot.
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == slide_level then
      local layout_name = get_attr_value(block.attributes, { "layout", "data-layout" })
      if layout_name ~= "" then
        inject_layout_marker_into_header(block, layout_name)
      end

      local hide_value = get_attr_value(block.attributes, {
        "hidden",
        "hide",
        "slide-hidden",
        "slide-hide",
        "data-hidden",
        "data-hide"
      })
      if hide_value ~= "" and truthy(hide_value) then
        inject_hide_marker_into_header(block)
        debug("slide hide marker injected from header attribute")
      end
    end
  end

  if #columns == 0 and #boxes == 0 and #captions == 0 and #text_blocks == 0 and footer == "" and location == "" and caption_size == "" and caption_dx == "" and caption_dy == "" then
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
    text_blocks = text_blocks,
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
