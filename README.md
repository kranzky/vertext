# Vertext

This is going to be a browser for the indie web, written in Flutter (using the
Dart language). The browser must be lightweight and fast, with versions for iOS,
Android, Mac and Windows desktop, together with a Web version so that users can
try it out without needing to download it first.

The browser should allow multiple documents to be open in separate tabs, and
should always show tabs in two side-by-side columns, where each column can
contain multiple tabs. When clicking on a link in one tab, the link should open
in a new tab in the other column. It should be possible to close tabs, re-open a
tab that has just been closed and drag tabs within a column to sort them or
between columns.

Tabs should show the title of the document rather than its URL. The title should
be inferred from the contents of the document.

To make the browser very lightweight, it must not use any HTML rendering at all.
Instead, the browser is only able to retrieve and render MarkDown documents, and
these can be rendered using the appropriate Flutter widgets.

The renderer should support github flavoured markdown, but should be extensible
so that it can support rendering mathtex equations in a future release, for
example.

Other things that we want to anticipate including in a future release are:

* User-selected themes that change fonts, colour and layout
* Caching of the downloaded markdown documents and included images
* Pre-retrieval and caching of links to other markdown documents
* Print a document

The browser should begin with the following home page: https://mmm.kranzky.com

Note that mmm stands for the "Massive Markdown Matrix", as opposed to www which
stands for the "World Wide Web".

To begin with, build the simplest possible version of this project that
correctly renders the home page.


