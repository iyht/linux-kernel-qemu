
DOCKER_IMAGE = lke
HOST_NAME = foo
PHONY: clean image run

# create the docker image
docker-create-image:
	sudo docker build -t $(DOCKER_IMAGE) .

# run the docker image
docker-run-bash:
	sudo docker run -it --rm \
	--hostname $(HOST_NAME) \
	-v $(PWD):/home/$(HOST_NAME) \
	--privileged \
	-w /home/$(HOST_NAME) \
	$(DOCKER_IMAGE)