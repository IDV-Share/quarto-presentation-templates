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


## TODO
- add embed-video
- add usage for ambed-video
- add python requirements
- add additional requirements such as make and conda
- explain repository structure
- make dummy guide files in main branch to guide the user to a proper use.
- same python postprocess to force the use of specific slide layouts