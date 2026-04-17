{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

if [ -d starter ]; then
  cd starter
  node_modules/grunt-cli/bin/grunt vb-clean
else
  mkdir starter
  cd starter
  unzip ../starter.zip
  npm install
fi    
node_modules/grunt-cli/bin/grunt vb-process-local
exit_on_error
cd ..

mkdir -p html
rm -Rf html/*
cp -r starter/build/processed/webApps/starter/* html/.

# Common Function
build_ui