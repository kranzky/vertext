# Anchor Links Demo

This page demonstrates how anchor links work in Vertext. Anchor links let you navigate to specific sections within a document.

## Table of Contents

- [Introduction](#introduction)
- [How Anchor Links Work](#how-anchor-links-work)
- [Creating Anchor Links](#creating-anchor-links)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Conclusion](#conclusion)

## Introduction

Welcome to the anchor links demo! Anchor links are a powerful feature of markdown documents that allow you to create a table of contents and navigate quickly between sections.

## How Anchor Links Work

Anchor links work by creating a link to a specific section within the current document. When clicked, the document scrolls to that section. In HTML, this is implemented using fragment identifiers (the part of a URL after the # symbol).

In markdown, every heading automatically becomes an anchor point you can link to.

## Creating Anchor Links

To create an anchor link in markdown, use this syntax:

```markdown
[Link Text](#heading-id)
```

The heading ID is automatically generated from the heading text:
1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove special characters

For example, the heading "Creating Anchor Links" becomes `#creating-anchor-links`.

## Best Practices

When using anchor links, consider these best practices:

- Create a table of contents for long documents
- Use descriptive heading names
- Keep anchor links current when headings change
- Test all anchor links after making changes

## Examples

Here are some examples of anchor links:

- Jump to [Introduction](#introduction)
- Go back to [Table of Contents](#table-of-contents)
- Learn about [How Anchor Links Work](#how-anchor-links-work)

You can also create links to very specific sections. For example, link to the [Best Practices](#best-practices) section.

![App Icon](../icons/app_icon.svg)

This image is referenced with a relative path: `![App Icon](../icons/app_icon.svg)`

Invalid links (shown in grey):
- This section [does not exist](#non-existent-section)
- [Another invalid link](#missing-heading) that has no target

## Conclusion

Anchor links are a simple yet powerful way to improve navigation within long documents. They help readers find specific information quickly without scrolling through the entire document.

Now that you've learned about anchor links, try creating some in your own documents!

---

### Very Long Section To Demonstrate Scrolling

This section is intentionally long to demonstrate scrolling to anchors that are far down in the document.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl. Nullam auctor, nisl eget ultricies aliquam, nunc nisl aliquet nunc, eget aliquam nisl nunc eget nisl.

### Another Section Far Down

This is another section far down in the document. You can link to it with [#another-section-far-down](#another-section-far-down).

Now try clicking on [Back to Top](#anchor-links-demo) to return to the top of the document!