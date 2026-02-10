local placeholders = {}
local counter = 0

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

function Div(el)
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
  local img = first_image(el.content)
  if poster == "" and img ~= nil then
    poster = img.src
  end

  debug("placeholder id=" .. id .. " video=" .. video .. " poster=" .. (poster ~= "" and poster or "<none>"))

  local alt_text = "VIDEO::" .. id

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
    poster = poster
  })

  return placeholder
end

function Pandoc(doc)
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
