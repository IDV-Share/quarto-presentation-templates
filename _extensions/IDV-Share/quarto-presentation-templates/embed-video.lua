local videos = {}

local function normalize_path(path)
  -- Normalize Windows-style paths so the Python post-processor can resolve files on any OS.
  return string.gsub(path, "\\", "/")
end

function Div(el)
  if el.classes:includes("embed-video") then
    local poster = el.attributes.poster
    local video = el.attributes.video

    if poster and video then
      videos[normalize_path(poster)] = normalize_path(video)
      -- Return the content of the div so the image is still rendered
      -- The Python script will later replace the image with a video
      return el.content
    end
  end
  return el
end

function Pandoc(doc)
  if next(videos) == nil then
    return doc
  end

  local json = quarto.json.encode(videos)
  local f = io.open("embed-video.json", "w")

  if f == nil then
    error("Could not write embed-video.json")
  end

  f:write(json)
  f:close()

  local count = 0
  for _ in pairs(videos) do
    count = count + 1
  end

  print("[embed-video] wrote embed-video.json with " .. tostring(count) .. " mapping(s)")
  return doc
end
