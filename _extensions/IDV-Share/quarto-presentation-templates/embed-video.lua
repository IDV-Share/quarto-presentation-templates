local placeholders = {}
local counter = 0
local POSTPROCESS_DISABLED = nil
local VIDEO_PREFIX = "VIDEO::"

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

  local env = os.getenv("EMBED_VIDEO_DEBUG")
  if env and env ~= "" then
    return truthy(env)
  end
  if PANDOC_STATE and PANDOC_STATE.meta then
    return truthy(PANDOC_STATE.meta["embed-video-debug"])
  end
  return false
end

local function debug(msg)
  if debug_enabled() then
    io.stderr:write("[embed-video] " .. msg .. "\n")
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

local function first_image(blocks)
  for _, block in ipairs(blocks) do
    if block.t == "Para" or block.t == "Plain" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Image" then
          return inline
        end
      end
    end
  end
  return nil
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

local function strip_video_markers(doc)
  return doc:walk({
    Str = function(el)
      local text = el.text or ""
      if text:sub(1, #VIDEO_PREFIX) == VIDEO_PREFIX then
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

function Div(el)
  if postprocess_disabled_state() then
    return nil
  end

  if not has_class(el, "embed-video") then
    return nil
  end

  local video = el.attributes["video"] or el.attributes["data-video"] or ""
  if video == "" then
    debug("embed-video block missing video attribute; skipping.")
    return el
  end

  counter = counter + 1
  local id = el.identifier
  if id == nil or id == "" then
    id = "video-" .. tostring(counter)
  end

  local poster = el.attributes["poster"] or el.attributes["data-poster"] or ""
  local width = el.attributes["width"] or el.attributes["data-width"] or ""
  local height = el.attributes["height"] or el.attributes["data-height"] or ""
  local pos_x = el.attributes["x"] or el.attributes["left"] or el.attributes["data-x"] or el.attributes["data-left"] or ""
  local pos_y = el.attributes["y"] or el.attributes["top"] or el.attributes["data-y"] or el.attributes["data-top"] or ""
  local img = first_image(el.content)
  if poster == "" and img ~= nil then
    poster = img.src
  end

  debug("placeholder id=" .. id .. " video=" .. video .. " poster=" .. (poster ~= "" and poster or "<none>"))
  if width ~= "" or height ~= "" then
    debug("custom size width=" .. (width ~= "" and width or "<auto>") .. " height=" .. (height ~= "" and height or "<auto>"))
  end
  if pos_x ~= "" or pos_y ~= "" then
    debug("custom position x=" .. (pos_x ~= "" and pos_x or "<auto>") .. " y=" .. (pos_y ~= "" and pos_y or "<auto>"))
  end

  local alt_text = VIDEO_PREFIX .. id

  local placeholder = nil
  if poster ~= "" then
    if img ~= nil then
      img.caption = { pandoc.Str(alt_text) }
      img.title = ""
      placeholder = pandoc.Para({ img })
    else
      local attr = pandoc.Attr(id, {}, { ["data-video-id"] = id })
      local new_img = pandoc.Image({ pandoc.Str(alt_text) }, poster, "", attr)
      placeholder = pandoc.Para({ new_img })
    end
  else
    placeholder = pandoc.Para({ pandoc.Str(alt_text) })
  end

  table.insert(placeholders, {
    id = id,
    video = video,
    poster = poster,
    width = width,
    height = height,
    x = pos_x,
    y = pos_y
  })

  return placeholder
end

function Pandoc(doc)
  local disabled = postprocess_disabled_from_meta(doc.meta)
  POSTPROCESS_DISABLED = disabled
  if disabled then
    debug("postprocess disabled: embed-video placeholders skipped.")
    return strip_video_markers(doc)
  end

  if #placeholders == 0 then
    debug("no placeholders found.")
    return doc
  end

  local output = stringify_meta(doc.meta["embed-video-json"])
  if output == "" then
    output = "embed-video.json"
  end

  local ok, encoded = pcall(pandoc.json.encode, placeholders)
  if not ok then
    return doc
  end

  local file = io.open(output, "w")
  if file ~= nil then
    file:write(encoded)
    file:close()
    debug("wrote " .. tostring(#placeholders) .. " placeholder(s) to " .. output)
  end

  return doc
end
