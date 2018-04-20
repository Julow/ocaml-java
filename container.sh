IMAGE_NAME="ocaml-java-build"

docker build -t "$IMAGE_NAME" - < Dockerfile
docker run -it --rm -v"`pwd`:/app" "$IMAGE_NAME" bash
