TAG?=master

all: docker documentation

docker:
	docker build -t blizzlike/core-api:${TAG} --no-cache -f Dockerfile .

documentation:
	install -d ./docs/generated/html ./docs/generated/md
	raml2html --theme raml2html-kaa-theme ./docs/v1.raml > ./docs/generated/html/index.html
