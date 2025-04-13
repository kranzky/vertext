# TODO

## Now

* Get signed windows build uploaded

## Soon

* Full UI redesign.
  + Only the left column has tabs, and these are arranged vertically in a new
    column on the LHS of the display.
    - The icons to close a tab and re-open a tab remain for the left column only,
      and are at the top of the tab column. Remove the icon to switch tabs.
    - The right column has icons to open a file or url and save to a new tab.
  + Links always open in the right column, replacing what was there before.
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
  + The URL of either column can be copied by tapping an icon in the status bar.
* Single column for narrow mobile layouts that combines both columns (showing
  either a tab if selected or the content just clicked on).
* Implement a night mode.
* Get android and iphone builds working
* Release version 1.0

## Later

* Add a mode to show the table of contents, perhaps in a pop-out sidebar.
* Implement themes (fonts, colours, sizes etc).
* Make the web version open non-markdown links in a new tab.
* Get the file open dialog working for the web version.
* Strip out HTML tags (this will need to use the markdown parser to make sure
  that we still allow HTML tags in code blocks, for example).
* Allow :these: kinds of emojis to work (will probably require similar parsing
  to stripping out the image tags).
* Get code blocks working properly:
  + Monospace font
  + Syntax highlighting
