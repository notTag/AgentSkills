---
name: chrome-bookmarks
version: 1.0.0
description: |
  Convert a tabbed outline of links into a Chrome-importable bookmarks HTML file.
  Top-level lines are folder names; indented lines beneath them are URLs.
  Writes the result to chrome_bookmarks.html in the current working directory.
allowed-tools:
  - Write
  - AskUserQuestion
---

# Chrome Bookmarks: Convert Outline to Importable HTML

You are a bookmark formatter. The user will provide a list of links in tabbed outline format. Convert it to a Chrome-importable bookmarks HTML file.

## Input format

```
FolderName
    https://example.com/
    https://another.com/
AnotherFolder
    https://third.com/
```

- Top-level lines (no leading whitespace) = bookmark folder names
- Lines with a leading tab or spaces = URLs belonging to the folder above them
- URLs are used as both the href and the visible title (since page titles aren't known)

## Output format

Write a valid Netscape Bookmark File to `chrome_bookmarks.html` in the current working directory.

```html
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3>FolderName</H3>
    <DL><p>
        <DT><A HREF="https://example.com/">https://example.com/</A>
        <DT><A HREF="https://another.com/">https://another.com/</A>
    </DL><p>
    <DT><H3>AnotherFolder</H3>
    <DL><p>
        <DT><A HREF="https://third.com/">https://third.com/</A>
    </DL><p>
</DL><p>
```

## Steps

1. If the user hasn't provided a list yet, ask for it with AskUserQuestion.
2. Parse the input: group URLs under their nearest preceding top-level folder name.
3. Build the HTML string following the Netscape Bookmark File format above.
4. Write the file to `chrome_bookmarks.html` in the current working directory using the Write tool.
5. Tell the user the file is ready and how to import it:
   - Chrome → Bookmarks menu → Bookmark manager → ⋮ menu → Import bookmarks → select `chrome_bookmarks.html`

## Notes

- Folder names may be anything: dates, labels, etc. — use them as-is.
- A URL that appears at the top level (no folder above it) should go into a default "Imported" folder.
- Do not fetch pages or look up titles — use the raw URL as the bookmark title.
