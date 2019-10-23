# To read the Fission docs, go to: [docs.fission.io](https://docs.fission.io).

---

# Fission Docs Source Repo

This is the source for the [docs.fission.io](https://docs.fission.io)
website.  It contains docs for both the
[Fission](https://github.com/fission/fission) and [Fission
Workflows](https://github.com/fission/fission-workflows) projects.

## Repo organization and building

This is a [hugo](https://gohugo.io) statically-generated site, hosted
on [netlify](https://netlify.com).  The site is automatically built by
netlify (see netlify.toml and build.sh).

 * `docs/` is the source. It's a hugo site.
   * `docs/content` this is where the documentation content lives.
   * `docs/config.toml` is some hugo configuration, such as the base URL of the website, the theme etc.
 * `dist/` is the directory that's actually served at https://docs.fission.io
   * `dist/archive` has older versions of the docs are archived here. These are kept for reference purpose and will be eventually removed. All older versions are redirected to current version of docs
   * `dist/public` is the root of latest/live documentation
 * `build.sh` is run by netlify. It runs hugo and places the generated
   site under `dist/public`

## Making changes

### Adding a new doc

* You have to install **extended** version of Hugo in order to support SCSS/SASS.

```
$ cd docs/
$ npm install -D --save autoprefixer postcss-cli
$ hugo new usage/how-to-use-ShinyNewThing.md
```

### Modifying an existing doc

Find the doc under `docs/content`, edit it, make a pull request.  You
can use Github's handy UI for editing docs.

## Previewing your changes

```
$ cd docs/
$ hugo serve -D
# This will output a link that you can open in a browser.
```

## Publishing your changes

Make a pull request with your changes to the source.  There should be
no changes under the `dist` directory. When the pull request is merged the site will automatically be updated
by netlify.

