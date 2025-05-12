
PASSWORD :=
WINEPREFIX := $(realpath ./wineprefix)
INSTALLERS := $(realpath ./installers)

PORT := 3389

# https://github.com/containers/podman/issues/24934
PODMAN_UID := --uidmap +1000:@$(shell id -u):1
PODMAN_GID := --gidmap +1000:@$(shell id -g):1
PODMAN_RUN := podman run --rm -it -p $(PORT):3389 \
	 $(PODMAN_UID) $(PODMAN_GID) \
	-v $(WINEPREFIX):/opt/genome-studio/wineprefix:z \
	-v $(INSTALLERS):/opt/genome-studio/installers

NAME := genome-studio
TAG := $(shell git describe --always --dirty)
IMAGE := $(NAME):$(TAG)

all: run

build/$(NAME)_$(TAG).tar.gz: container
	mkdir -p build
	rm -fv build/$(NAME)_$(TAG).tar.gz
	podman save $(IMAGE) -o build/$(NAME)_$(TAG).tar.gz

build/$(NAME)_$(TAG).sif: build/$(NAME)_$(TAG).tar.gz
	rm -fv build/$(NAME)_$(TAG).sif
	singularity build $@ docker-archive://$<

bash: container
	$(PODMAN_RUN) --entrypoint bash $(IMAGE)

connect:
	xfreerdp3  /size:1920x1080 /v:localhost:$(PORT) /u:ubuntu /p:$(PASSWORD)

container:
	podman build -t $(IMAGE) -t $(NAME):latest .
	podman system prune --force

save: build/$(NAME)_$(TAG).tar.gz

run: container
	$(PODMAN_RUN) $(IMAGE)

.PHONY: run bash connect container save
