# Makefile for converting Quarto presentation to PowerPoint

QMD ?=
EXT = _extensions/IDV-Share/quarto-presentation-templates/embed_video.py

ifeq ($(QMD),)
    $(error Usage: make QMD=slides.qmd)
endif

PPTX := $(QMD:.qmd=.pptx)

# Define phony targets
.PHONY: all clean FORCE

# Default target
all: FORCE

FORCE: $(PPTX)

$(PPTX): $(QMD)
	quarto render $(QMD)
	python $(EXT) $(PPTX) .

# Clean target to remove generated PowerPoint file
clean:
	rm -f $(PPTX)