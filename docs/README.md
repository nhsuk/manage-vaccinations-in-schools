# Manage vaccinations in schools documentation

This directory contains documentation for the Manage vaccinations in schools service.

- [Architecture](architecture.adoc)
- [Offline Support](offline-support.adoc)
- [Offline CSRF Security](offline-csrf-security.adoc)

## Developing

### AsciiDoc

Much of the documentation here is in [AsciiDoc format](https://asciidoc.org/).
This has been chosen over MarkDown largely because it has built-in support to
render PlantUML diagrams, plus some other features which make document writing
nicer. While GitHub does support rendering AsciiDoc files while browsing a code
repository, it doesn't support a few features, most notably neither the
`include` directive nor the built-in diagram rendering. This has been
worked-around using other AsciiDoc features, please view existing documentation
for how to include diagrams in a way that works with both rendering using
`asciidoctor` and GitHub's built-in rendering.

#### Browser support

There is a [browser
extension](https://github.com/asciidoctor/asciidoctor-browser-extension) version
of `asciidoctor`, a commonly used AsciiDoc renderer. We recomment you install
this and use it to render raw AsciiDoc files natively in your browser. It
supports diagram rendering (see the extension settings to enable),
auto-reloading, and can be enabled / disabled easily, which can be convenient.

#### Rendering files locally

In addition to enabling rendering in the browser, you may want on occasion to
render AsciiDoc files locally. An example where this can be useful is when the
online renderer, [Kroki](https://kroki.io), is down and you want to continue to
work on some documentation (which happens on occassion, unfortunately). You
could use [asciidoctor](https://asciidoctor.org/) and the [asciidoctor-diagram
plugin](https://docs.asciidoctor.org/diagram-extension/latest/) to render the
files and diagrams locally. For example, to render the `architecture.adoc` file
you would run:

```sh
cd docs
asciidoctor -r asciidoctor-diagram architecture.adoc
```

You could also use `entr` (installed using brew, apt, etc) to automatically run
asciidoctor whenever a file is changed:

```sh
cd docs
ls *.adoc | entr -p asciidoctor -r asciidoctor-diagram /_
```
