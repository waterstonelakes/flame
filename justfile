default:
  just --list


todo:
  #!/usr/bin/env bash
  set -euo pipefail
  mkdir -p work
  f="work/$(date -u +%F)-$(openssl rand -hex 4)-todo.md"
  printf '# To Do\n\n' > "$f"
  echo "created $f"


install:
  cd flame-odm && yarn install
  cd web && yarn install


build: build-flame build-web


sync-down:
  git fetch --prune origin
  git pull --ff-only


sync-up:
  #!/usr/bin/env bash
  set -euo pipefail
  git push
  git fetch --prune origin
  gone=$(git branch --format '%(refname:short) %(upstream:track)' | awk '$2 == "[gone]" {print $1}')
  [ -n "$gone" ] && echo "$gone" | xargs git branch -d || true


[working-directory: 'flame-odm']
build-flame:
  rm -rf ./build
  ./node_modules/.bin/coffee --compile --no-header --output ./build ./lib


[working-directory: 'flame-odm']
test-flame:
  ./node_modules/.bin/mocha --parallel --require coffeescript/register --reporter list './tests/**/*.coffee'


[working-directory: 'flame-odm']
[no-exit-message]
test-watch-flame:
  ./node_modules/.bin/chokidar './**/*.coffee' -c "./node_modules/.bin/mocha --slow 700 --parallel --require coffeescript/register --reporter list ./tests/e2e/pager-wip.coffee"


bump-flame:
  #!/usr/bin/env bash
  set -euo pipefail
  (cd flame-odm && ./node_modules/.bin/bump)
  version=$(grep -m1 '"version"' flame-odm/package.json | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
  tmp=$(mktemp)
  sed -E 's|^([[:space:]]*)v[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$|\1v'"${version}"'|' web/src/routes/docs/template.pug > "$tmp"
  mv "$tmp" web/src/routes/docs/template.pug
  git commit -m "release: v${version}" flame-odm/package.json web/src/routes/docs/template.pug
  git tag "v${version}"
  echo "released v${version} — flame-odm + docs version synced, committed, tagged"


[working-directory: 'flame-odm']
publish-flame: build-flame
  npm publish


[working-directory: 'web']
[no-exit-message]
serve-web:
  ./node_modules/.bin/vite dev --clearScreen false --port 8007 --host


[working-directory: 'web']
build-web:
  ./node_modules/.bin/vite build
  cp -R ./.vercel ./build
  cp vercel.json ./build


[working-directory: 'web']
[no-exit-message]
preview-web:
  ./node_modules/.bin/vite preview --port 8007


[working-directory: 'web']
deploy-web: build-web
  cd build && vc


[working-directory: 'web']
deploy-web-production: build-web
  cd build && vc --prod
