.PHONY: pptx clean

QMD ?= template.qmd
PPTX ?= $(basename $(QMD)).pptx
MAP ?= embed-video.json
LAYOUT ?= pptx-layout.json
PYTHON ?= python
POSTPROC_SCRIPT ?= _extensions/IDV-Share/quarto-presentation-templates/postprocess.py

pptx:
	quarto render $(QMD)
	$(PYTHON) $(POSTPROC_SCRIPT) --input $(PPTX) --mapping $(MAP) --layout $(LAYOUT)

clean:
	rm -f $(PPTX) $(MAP) $(LAYOUT)
