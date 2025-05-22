docker run -d \
  -f dev.environment.Dockerfile \
  --name arch-dev \
  -p 2222:22 \
  -v "$(pwd):/workspace" \
  my-arch-dev-env