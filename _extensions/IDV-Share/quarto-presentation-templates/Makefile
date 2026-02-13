.PHONY: pptx clean deps env

QMD ?= template.qmd
PPTX ?= $(basename $(QMD)).pptx
MAP ?= embed-video.json
LAYOUT ?= pptx-layout.json
PYTHON ?= python
POSTPROCESS ?= auto
DEBUG ?= 0
QMD_TARGETS := $(wildcard *.qmd)

EXT_DIR ?= _extensions/IDV-Share/quarto-presentation-templates
EXT_MAKEFILE ?= $(EXT_DIR)/Makefile
POSTPROC_SCRIPT ?= $(EXT_DIR)/postprocess.py
REQ_FILE ?= $(EXT_DIR)/requirements.txt
ENV_FILE ?= $(EXT_DIR)/environment.yml

.PHONY: $(QMD_TARGETS)

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
	$(MAKE) -f "$(EXT_MAKEFILE)" clean QMD="$(QMD)"
	quarto render "$(QMD)" $(QUARTO_LOG)
ifeq ($(POSTPROCESS),1)
	$(PYTHON) "$(POSTPROC_SCRIPT)" --input "$(PPTX)" --mapping "$(MAP)" --layout "$(LAYOUT)" $(POSTPROC_DEBUG)
else
	@echo "Skipping postprocess (disable-postprocess=true or POSTPROCESS=0)."
endif

$(QMD_TARGETS):
	$(MAKE) -f "$(EXT_MAKEFILE)" pptx QMD="$@"

%.qmd:
	$(MAKE) -f "$(EXT_MAKEFILE)" pptx QMD="$@"

deps:
	$(PYTHON) -m pip install -r "$(REQ_FILE)"

env:
	conda env create -f "$(ENV_FILE)"

clean:
ifeq ($(OS),Windows_NT)
	-@if exist "$(PPTX)" del /Q "$(PPTX)" 2>nul
	-@if exist "$(MAP)" del /Q "$(MAP)" 2>nul
	-@if exist "$(LAYOUT)" del /Q "$(LAYOUT)" 2>nul
else
	-@rm -f "$(PPTX)" "$(MAP)" "$(LAYOUT)"
endif
