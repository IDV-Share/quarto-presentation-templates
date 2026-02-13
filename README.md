# Quarto Presentation Templates

Reusable Quarto extensions for presentations:

- 🎓 Beamer (PDF)
- 🌐 RevealJS (HTML)
- 📊 PowerPoint (PPTX)

## Installation

### Environment Setup

To setup the python environment with conda and install the required dependencies, run:

```bash
conda env create -f environment.yml
conda activate quarto
```

### Quarto Extensions

You can install the extensions using the Quarto CLI:

```bash
quarto add IDV-Share/quarto-presentation-templates
```

Or you can use as a starting template for your presentation:

```bash
quarto use template IDV-Share/quarto-presentation-templates
```

### Disable Postprocess (PPTX)

Set `disable-postprocess: true` in your document metadata to skip marker-based postprocessing and render with plain Quarto only.
`make pptx` also detects this flag and skips `postprocess.py` automatically.