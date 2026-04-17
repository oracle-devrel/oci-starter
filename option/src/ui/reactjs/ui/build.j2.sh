{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

cd src
npm install
npm run build
cd ..

mkdir -p html
rm -Rf html/*
cp -r src/build/* html/.

# Common
build_ui
