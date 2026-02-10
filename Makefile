.PHONY: pptx clean

QMD ?= template.qmd
PPTX ?= $(basename $(QMD)).pptx
MAP ?= embed-video.json
LAYOUT ?= pptx-layout.json
PYTHON ?= python
POSTPROC_SCRIPT ?= _extensions/IDV-Share/quarto-presentation-templates/postprocess.py
MISC_FILENAMES := $(PPTX) $(MAP) $(LAYOUT)
MISC_FILES := $(strip $(foreach f,$(MISC_FILENAMES),$(wildcard $(f))))
DEBUG ?= 0

QUARTO_LOG :=
POSTPROC_DEBUG :=
ifeq ($(DEBUG),1)
QUARTO_LOG = --log-level=debug
POSTPROC_DEBUG = --debug
endif

pptx:
	$(MAKE) clean
	quarto render $(QMD) $(QUARTO_LOG)
	$(PYTHON) $(POSTPROC_SCRIPT) --input $(PPTX) --mapping $(MAP) --layout $(LAYOUT) $(POSTPROC_DEBUG)


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
