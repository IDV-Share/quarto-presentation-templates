.PHONY: pptx clean deps env

QMD ?= template.qmd
EXT_DIR ?= _extensions/IDV-Share/quarto-presentation-templates
EXT_MAKEFILE ?= $(EXT_DIR)/Makefile
QMD_TARGETS := $(wildcard *.qmd)

.PHONY: $(QMD_TARGETS)

ifeq ($(wildcard $(EXT_MAKEFILE)),)
$(error Missing $(EXT_MAKEFILE). Install the extension first: quarto add IDV-Share/quarto-presentation-templates)
endif

pptx clean deps env:
	$(MAKE) -f "$(EXT_MAKEFILE)" $@ QMD="$(QMD)"

$(QMD_TARGETS):
	$(MAKE) -f "$(EXT_MAKEFILE)" "$@"

%.qmd:
	$(MAKE) -f "$(EXT_MAKEFILE)" "$@"
