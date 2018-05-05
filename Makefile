all: documentation

documentation:
	install -d ./docs/generated/html ./docs/generated/md
	raml2html --theme raml2html-kaa-theme ./docs/v1.raml > ./docs/generated/html/index.html
