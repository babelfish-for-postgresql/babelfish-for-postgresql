# Building tarballs

The `build.sh` script will output the tarballs into the `/tmp/build` folder, and
output their paths.

If you have the link for the releases notes, you can export the below variable
before the build execution:

```bash
export RELEASE_NOTES_LINK="https://raw.githubusercontent.com/babelfish-for-postgresql/babelfish_project_website/0c12e48306ef89a2d9fa62c8a55b93d8705b9ac1/_artifacts/babelfish/babelfish-2.1.1-source-x64.markdown"
./build.sh
```