# My Org PowerPoint Template

This Quarto extension provides a PowerPoint (`.pptx`) reference document
to enforce consistent branding.

## Features

- Corporate fonts and colors
- Master slide layouts
- Header-level hidden-slide flag (`{hidden=true}` / `{hide=true}`)
- Logo placement
- Compatible with Quarto PPTX output
- Postprocess styling for full `:::` text blocks (`font-size`, `font-style`, `font-weight`, `font-family`)

## Hidden Slides

Mark a slide as hidden in the final PowerPoint slideshow using a header attribute:

```markdown
## Internal Backup Slide {hidden=true}
```

Alias:

```markdown
## Internal Backup Slide {hide=true}
```

## Full Div Text Styling

Style an entire div block in PPTX with attributes or CSS-style values.
These settings are applied by `postprocess.py` (Windows `msoffice` backend).
Styling is scoped to text inside the fenced block only.
Bullet lists and nested lists inside the fenced block are supported.

Named size classes are handled directly by `pptx-layout.lua` and are supported on fenced divs:
`.LARGE`, `.Large`, `.large`, `.normal`, `.small`, `.Small`, `.SMALL`, `.tiny`, `.Tiny`, `.TINY`.

```markdown
::: {font-size="18pt" font-style="italic" font-family="Calibri"}
This whole block is styled in PowerPoint.
:::

::: {style="font-size:14pt; font-weight:bold; font-family:Arial;"}
This whole block is bold and uses Arial.
:::

:::{.Large}
This whole fenced block uses the `Large` size preset.
:::
```

## Disable Postprocess

To render with plain Quarto only (no postprocess markers/placeholders), set:

```yaml
format:
  quarto-presentation-templates-pptx:
    disable-postprocess: true
```

This disables marker injection in Lua filters (`pptx-layout.lua`, `embed-video.lua`).

## Build Tooling

This extension ships its own build and dependency files:

- `Makefile`
- `requirements.txt`
- `environment.yml`

Direct usage from a project root:

```bash
make -f _extensions/IDV-Share/quarto-presentation-templates/Makefile pptx QMD=template.qmd
make -f _extensions/IDV-Share/quarto-presentation-templates/Makefile template.qmd
```

Optional root wrapper (for short commands like `make template.qmd`):

```make
.PHONY: pptx clean
EXT_MAKEFILE := _extensions/IDV-Share/quarto-presentation-templates/Makefile

pptx clean:
	$(MAKE) -f "$(EXT_MAKEFILE)" $@

%.qmd:
	$(MAKE) -f "$(EXT_MAKEFILE)" "$@"
```


## For Developers

To create a PowerPoint template, start with a reference PPTX file that defines your desired styles and layouts. Then, use the following command to generate the template from your reference document:

```bash
quarto pandoc -o IDV-template.pptx --print-default-data-file reference.pptx
```

Change the style of the generated `IDV-template.pptx` as needed, and place it in the extension's `resources` folder. Update the `_extension.yml` to point to your template file.
