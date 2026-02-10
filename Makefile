.PHONY: pptx clean

QMD ?= template.qmd
PPTX ?= $(basename $(QMD)).pptx
MAP ?= embed-video.json
PYTHON ?= python
EMBED_SCRIPT ?= _extensions/IDV-Share/quarto-presentation-templates/embed-video.py

pptx:
	quarto render $(QMD)
	$(PYTHON) $(EMBED_SCRIPT) --input $(PPTX) --mapping $(MAP)

clean:
	rm -f $(PPTX) $(MAP)
