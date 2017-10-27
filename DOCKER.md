# Docker

There are two things which must be set apart.

1. Images
2. Containers

---

An image is a build, a pre-made instance - of for example - ETEngine.
This contains all the code needed to be able to run but it doesn't yet.

Once you load an image into a container, it starts running.

How to update the build?

`docker-compose build web`

List all images:

`docker images`

Run a specific container:

`docker-compose up`
