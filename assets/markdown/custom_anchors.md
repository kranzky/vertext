# Markdown Documentation: Custom Anchor IDs

This document demonstrates custom anchor IDs that are common in many markdown documentation sites.

## Table of Contents

*   [Overview](#overview)
    *   [Philosophy](#philosophy)
    *   [Inline HTML](#html)
    *   [Automatic Escaping for Special Characters](#autoescape)
*   [Block Elements](#block)
    *   [Paragraphs and Line Breaks](#p)
    *   [Headers](#header)
    *   [Blockquotes](#blockquote)
    *   [Lists](#list)
    *   [Code Blocks](#precode)
    *   [Horizontal Rules](#hr)
*   [Span Elements](#span)
    *   [Links](#link)
    *   [Emphasis](#em)
    *   [Code](#code)
    *   [Images](#img)
*   [Miscellaneous](#misc)
    *   [Backslash Escapes](#backslash)
    *   [Automatic Links](#autolink)

## Overview

### Philosophy

Markdown is intended to be as easy-to-read and easy-to-write as is feasible.

Readability, however, is emphasized above all else. A Markdown-formatted
document should be publishable as-is, as plain text, without looking
like it's been marked up with tags or formatting instructions.

## Block Elements 

### Paragraphs and Line Breaks

A paragraph is simply one or more consecutive lines of text, separated
by one or more blank lines. Normal paragraphs should not be indented with spaces or tabs.

### Headers

Markdown supports two styles of headers, Setext and atx.

Optionally, you may "close" atx-style headers. This is purely
cosmetic -- you can use this if you think it looks better.

## Span Elements

### Links

Markdown supports two style of links: inline and reference.

Inline links use the following syntax:

```
[Link Text](URL "Optional Title")
```

Reference-style links are written like this:

```
[Link Text][ID]
```

### Code

To indicate a span of code, wrap it with backtick quotes (`).

## Miscellaneous

### Backslash Escapes

Markdown allows you to use backslash escapes to generate literal characters which would otherwise have special meaning in Markdown's formatting syntax.

### Images {#img}

Markdown uses an image syntax that is intended to resemble the syntax for links, allowing for two styles: inline and reference.

For example:

```
![Alt text](/path/to/img.jpg)
![Alt text](/path/to/img.jpg "Optional title")
```