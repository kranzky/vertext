# TODO

## Now

* Make sure we can load relative image paths.
* Publish an mmm version of my diary at https://kranzky.github.io/mmm/index.md
* Get code blocks working properly:
  + Monospace font
  + Syntax highlighting

## Soon

* Make the web version open non-markdown links in a new tab.
* Get the file open dialog working for the web version.

## Later

* Full UI redesign.
  + Only the left column has tabs, and these can be arranged vertically in a new
    column on the LHS of the display.
    - The icons to add a tab and re-open a tab remain for the left column only,
      and are at the top of the tab column. Remove the icon to switch tabs.
  + Links always open in the right tab, replacing what was there before.
    - The exception is that if the link is already open, the tab it is in will
      be brought to front, and a toast message will alert the user.
  + The right column can be saved to a tab, and has back/forward buttons to
    capture the full history of the session. This history is not persisted (so
    the right column will always be empty when starting a new session). Error
    pages are not included in the history. This means that the three rightmost
    buttons will apply to the right column (forwards, backwards, save-to-tab).
    The remainder of the UI (tabs, add page, reopen) apply to the left column.
  + Tabs can either be closed or saved (which also closes them, but adds a link
    to the bookmarks). The bookmarks can be viewed and re-ordered, and
    individual entries can be deleted.
  + When viewing a document a table of contents can be accessed.
  + The URL of either column can be copied by tapping an icon in the status bar.
* Different column layout on mobile in portrait mode. Either the two columns are
  stacked on top of each other or the user can quickly switch between the left
  and right columns.
* Implement a night mode.
* Add a mode to show the table of contents, perhaps in a pop-out sidebar.
* Implement themes (fonts, colours, sizes etc).
* Strip out HTML tags (this will need to use the markdown parser to make sure
  that we still allow HTML tags in code blocks, for example).
* Allow :these: kinds of emojis to work (will probably require similar parsing
  to stripping out the image tags).
* Package for distribution and launch version 1.0.
