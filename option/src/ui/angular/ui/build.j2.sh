{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

cd src
npm install
npm install @angular/cli
node_modules/.bin/ng build
cd ..

mkdir -p html
rm -Rf html/*
cp -r src/dist/example-app/* html/.

# Common
build_ui
