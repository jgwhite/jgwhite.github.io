docker \
  run \
  -v $PWD:/usr/src/app \
  -p 4000:4000 \
  -i \
  -t \
  --rm \
  starefossen/github-pages
