image=docker.pkg.github.com/nais/ipblocks-sync/ipblocks-sync:0.14

build:
	docker build -t ${image} .

push:
	docker push ${image}

release: build push
