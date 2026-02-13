.PHONY: pptx clean

QMD ?= template.qmd
PPTX ?= $(basename $(QMD)).pptx
MAP ?= embed-video.json
LAYOUT ?= pptx-layout.json
PYTHON ?= python
POSTPROC_SCRIPT ?= _extensions/IDV-Share/quarto-presentation-templates/postprocess.py
POSTPROCESS ?= auto
MISC_FILENAMES := $(PPTX) $(MAP) $(LAYOUT)
MISC_FILES := $(strip $(foreach f,$(MISC_FILENAMES),$(wildcard $(f))))
DEBUG ?= 0

ifeq ($(POSTPROCESS),auto)
POSTPROCESS := $(shell $(PYTHON) -c "import pathlib; p=pathlib.Path(r'$(QMD)'); t=p.read_text(encoding='utf-8').lower().splitlines() if p.exists() else []; print('0' if any(((s.startswith('disable-postprocess:') or s.startswith('disable_postprocess:')) and s.split(':',1)[1].strip() in ('true','1','yes','on')) for s in (line.split('#',1)[0].strip() for line in t)) else '1')")
endif

QUARTO_LOG :=
POSTPROC_DEBUG :=
ifeq ($(DEBUG),1)
QUARTO_LOG = --log-level=debug
POSTPROC_DEBUG = --debug
endif

pptx:
	$(MAKE) clean
	quarto render $(QMD) $(QUARTO_LOG)
ifeq ($(POSTPROCESS),1)
	$(PYTHON) $(POSTPROC_SCRIPT) --input $(PPTX) --mapping $(MAP) --layout $(LAYOUT) $(POSTPROC_DEBUG)
else
	@echo "Skipping postprocess (disable-postprocess=true or POSTPROCESS=0)."
endif


clean:
ifeq ($(OS),Windows_NT)
# Windows
	-@if exist "$(PPTX)" del /Q "$(PPTX)" 2>nul
	-@if exist "$(MAP)" del /Q "$(MAP)" 2>nul
	-@if exist "$(LAYOUT)" del /Q "$(LAYOUT)" 2>nul
else
# Unix/Linux/macOS
	-@rm -f $(PPTX) $(MAP) $(LAYOUT)
endif
