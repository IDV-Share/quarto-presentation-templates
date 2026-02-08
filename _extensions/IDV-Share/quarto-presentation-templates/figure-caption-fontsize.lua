-- figure-caption-fontsize.lua

local META = PANDOC_STATE and PANDOC_STATE.meta or {}

local CAPTION_SIZE =
  META.figure_caption_size
  and pandoc.utils.stringify(META.figure_caption_size)
  or "9pt"

function Figure(fig)
  if not fig.caption or not fig.caption.long then
    return nil
  end

  local new_long = {}

  for _, block in ipairs(fig.caption.long) do
    if block.t == "Plain" or block.t == "Para" then
      table.insert(
        new_long,
        pandoc.Para({
          pandoc.Span(
            block.content,
            pandoc.Attr("", {}, { ["font-size"] = CAPTION_SIZE })
          )
        })
      )
    else
      table.insert(new_long, block)
    end
  end

  fig.caption.long = new_long
  return fig
end