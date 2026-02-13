# My Org PowerPoint Template

This Quarto extension provides a PowerPoint (`.pptx`) reference document
to enforce consistent branding.

## Features

- Corporate fonts and colors
- Master slide layouts
- Logo placement
- Compatible with Quarto PPTX output
- Postprocess styling for full `:::` text blocks (`font-size`, `font-style`, `font-weight`, `font-family`)

## Full Div Text Styling

Style an entire div block in PPTX with attributes or CSS-style values.
These settings are applied by `postprocess.py` (Windows `msoffice` backend).

```markdown
::: {font-size="18pt" font-style="italic" font-family="Calibri"}
This whole block is styled in PowerPoint.
:::

::: {style="font-size:14pt; font-weight:bold; font-family:Arial;"}
This whole block is bold and uses Arial.
:::
```


## For Developers

To create a PowerPoint template, start with a reference PPTX file that defines your desired styles and layouts. Then, use the following command to generate the template from your reference document:

```bash
quarto pandoc -o IDV-template.pptx --print-default-data-file reference.pptx
```

Change the style of the generated `IDV-template.pptx` as needed, and place it in the extension's `resources` folder. Update the `_extension.yml` to point to your template file.
