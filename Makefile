build:
	run-rstblog build

serve:
	run-rstblog serve

upload:
	scp -r _build/* mattdeboard.net:/a/mattdeboard.net/root

clean:
	rm -rf _build/
