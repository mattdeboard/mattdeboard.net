SLUG=slugified-title
FOLDER=`date +%Y/%m/%d/`
ENTRY=$(FOLDER)$(SLUG).rst

build:
	run-rstblog build

index:
	cp _build/index.html .
serve:
	run-rstblog serve

upload:
	scp -r _build/* matt1:/a/mattdeboard.net/root

clean:
	rm -rf _build/

entry:
	mkdir -p $(FOLDER)
	touch $(ENTRY)
	echo "public: yes" >> $(ENTRY)
	echo "tags: []" >> $(ENTRY)
	echo "summary: " >> $(ENTRY)
