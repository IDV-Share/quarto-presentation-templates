# My Org PowerPoint Template

This Quarto extension provides a PowerPoint (`.pptx`) reference document
to enforce consistent branding.

## Features

- Corporate fonts and colors
- Master slide layouts
- Logo placement
- Compatible with Quarto PPTX output


## For Developers

To create a PowerPoint template, start with a reference PPTX file that defines your desired styles and layouts. Then, use the following command to generate the template from your reference document:

```bash
quarto pandoc -o IDV-template.pptx --print-default-data-file reference.pptx
```

Change the style of the generated `IDV-template.pptx` as needed, and place it in the extension's `resources` folder. Update the `_extension.yml` to point to your template file.