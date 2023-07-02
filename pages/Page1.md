+++
title = "Page 1"
hascode = true
date = Date(2023, 6, 30)
rss = "A short description of the page which would serve as **blurb** in a `RSS` feed; you can use basic markdown here but the whole description string must be a single line (not a multiline string). Like this one for instance. Keep in mind that styling is minimal in RSS so for instance don't expect maths or fancy styling to work; images should be ok though: ![](https://upload.wikimedia.org/wikipedia/en/3/32/Rick_and_Morty_opening_credits.jpeg)"

tags = ["syntax", "code"]
+++


# First page

\toc

## Live evaluation of code blocks

If you would like to show code as well as what the code outputs, you only need to specify where the script corresponding to the code block will be saved.

Indeed, what happens is that the code block gets saved as a script which then gets executed.
This also allows for that block to not be re-executed every time you change something _else_ on the page.
