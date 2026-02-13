---
author:
- John Doe
authors:
- John Doe
bibliography: references.bib
date: 2026-02-13
extensions:
- IDV-Share/quarto-presentation-templates@ppt
location: Your Location
title: PowerPoint Example
toc-title: Table of contents
---

<!-- Title Slide is inserted automatically -->

## Slide

-   This uses the IDV PPT template.
-   Pandoc will automatically apply the correct slide layout based on
    the content of each slide.

<!--- FIXME: pause is not yet supported in PowerPoint output -->
<!-- . . . -->

-   **Bold text** and *italic text*.
-   A list of supported pptx options can be found in the [Quarto
    documentation](https://quarto.org/docs/reference/formats/presentations/pptx.html).

------------------------------------------------------------------------

## My custom layout slide {#my-custom-layout-slide layout="1_Title and Content"}

-   This slide explicitly requests the `Title and Content` master
    layout.
-   Replace `Title and Content` with the exact layout name from your
    `.pptx` template.
-   This is applied by `postprocess.py` (Windows `msoffice` backend).
-   You can still use `\LAYOUT::...` markers, but header attributes are
    preferred.
-   To write marker keywords as plain text, escape the prefix:
    `\\LAYOUT::...` (same for `\\COLUMN::`, `\\BOX::`, `\\CAPTION::`,
    `\\VIDEO::`, ...).

------------------------------------------------------------------------

## Text size filter

[This is LARGE text]{.LARGE}

[This is Large text]{.Large}

[This is large text]{.large}

[This is NORMAL text]{.normal}

[This is small text]{.small}

[This is Small text]{.Small}

[This is SMALL text]{.SMALL}

[This is tiny text]{.tiny}

[This is Tiny text]{.Tiny}

[This is TINY text]{.TINY}

------------------------------------------------------------------------

## Styled div block

::: {style="font-size:14pt; font-weight:bold; font-family:Arial;"}
-   This whole `:::` block is styled by `postprocess.py`.
-   Supported attributes: `font-size`, `font-style`, `font-weight`,
    `font-family` (or via `style="..."`).
-   Useful when Quarto/Pandoc cannot force these properties directly in
    PPTX.
:::

------------------------------------------------------------------------

## Custom color filter

This is [red text]{style="color:#FF0000;"}.

This is [green text]{style="color:#00FF00;"}.

This is [blue text]{style="color:#0000FF;"}.

Syntax: `[text]{style="color:#RRGGBB;"}`

## Slide with text and image

This slide contains both text and an image.

![Example Image](resources/media/viking-hero.jpg)

------------------------------------------------------------------------

<!-- ## Figure caption styling

:::: {.columns}
::: {.column style="width: 40%; vertical-align: top;"}
![Default caption size (from metadata)](resources/media/viking-hero.jpg)
:::
::: {.column style="width: 60%; vertical-align: bottom;"}
![Custom caption size + offset](resources/media/superav_home.jpg){cap-size="10pt" cap-dy="0.15in"}
:::
:::: -->

------------------------------------------------------------------------

<!-- SECTION  HEADER SLIDE-->

# Section Header Slide

------------------------------------------------------------------------

-   No title, just content.

------------------------------------------------------------------------

## incremental list

<!--- FIXME: incremental list is not working --->
<!-- ::: {.incremental}
- Eat spaghetti
- Drink wine
::: -->

1.  Eat spaghetti
2.  Drink wine

------------------------------------------------------------------------

## non incremental list

<!--- FIXME: non incremental list is not working --->
<!-- ::: {.nonincremental}
- Eat spaghetti
- Drink wine
::: -->

-   Eat spaghetti
-   Drink wine

------------------------------------------------------------------------

## Two-column layout

::::: columns
::: {.column style="width: 40%; vertical-align: top;"}
Column 1. Widht 40% of the slide. Aligned to the top.
:::

::: {.column style="width: 60%; vertical-align: bottom;"}
Column 2. Widht 60% of the slide. Aligned to the bottom.
:::
:::::

------------------------------------------------------------------------

## Custom text box

This slide hase some content and some custom text boxes.

::: {.pptx-box width="10cm" height="2in" x="20%" y="200pt" style="vertical-align: middle;"}
This text is placed inside a custom box.
:::

------------------------------------------------------------------------

# Slide Title {#slide-title background-image="resources/media/tank_tracks_on_the_ground_sky_reflecting.jpg"}

------------------------------------------------------------------------

## Slide with speaker notes

Slide content

::: notes
Speaker notes go here.
:::

------------------------------------------------------------------------

## Tables

  Tables                Are           Cool
  --------------- --------------- --------
  col 3 is         right-aligned    \$1600
  col 2 is           centered         \$12
  zebra stripes      are neat          \$1

------------------------------------------------------------------------

## Mathematical expressions

Inline math: $E=mc^2$.

Display math: $$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$

------------------------------------------------------------------------

## Mermaid diagrams

<!-- FIXME: wron slide format selected by pandoc -->

:::::: {.cell layout-align="default"}
::::: cell-output-display
<div>

`<figure class=''>`{=html}

<div>

![](template_files\figure-markdown\mermaid-figure-1.png)

</div>

`</figure>`{=html}

</div>
:::::
::::::

------------------------------------------------------------------------

## code c++

``` cpp
#include <iostream>

int main() {
  std::cout << "Hello, World!" << std::endl;
  return 0;
}
```

## code matlab

``` matlab
x = linspace(0, 10, 100);
y = sin(x);
```

------------------------------------------------------------------------

## code python

``` python
import matplotlib.pyplot as plt
import numpy as np
x = np.linspace(0, 10, 100)
y = np.sin(x)
plt.plot(x, y)
plt.show()
```

------------------------------------------------------------------------

::: {.cell tags="[\"parameters\"]" execution_count="1"}
``` {.python .cell-code}
alpha = 0.1
ratio = 0.1
```
:::

## Slide with executed python code

::::::: columns
::: column
``` python
import matplotlib.pyplot as plt
import numpy as np
x = np.linspace(0, 10, 100)
y = np.sin(x) * alpha + np.cos(x) * ratio
plt.plot(x, y)
plt.show()
```
:::

<!--- FIXME: vertical align is not supported in PowerPoint output --->

::::: column
:::: {.cell width="200px" execution_count="2"}
``` {.python .cell-code}
import matplotlib.pyplot as plt
import numpy as np
x = np.linspace(0, 10, 100)
y = np.sin(x) * alpha + np.cos(x) * ratio
plt.plot(x, y)
plt.show()
```

::: {.cell-output .cell-output-display}
![](template_files/figure-markdown/fig-example-output-1.png)
:::
::::
:::::
:::::::

------------------------------------------------------------------------

## images python

:::: {.cell fig-width="40%" execution_count="3"}
``` {.python .cell-code}
import matplotlib.pyplot as plt
import matplotlib.image as mpimg

# Load images
images = [
  mpimg.imread('resources/media/superav_home.jpg'),
  mpimg.imread('resources/media/viking-hero.jpg'),
  mpimg.imread('resources/media/mtv_desert-e1744197429858.jpg'),
  mpimg.imread('resources/media/idv_modular_hero-e1744210155227.jpg')
]

captions = ['SUPERAV Home', 'Viking Hero', 'MTV Desert', 'IDV Modular Hero']

# Create a 2x2 subplot
fig, axs = plt.subplots(2, 2, figsize=(10, 10))

# Plot images with captions
for ax, img, caption in zip(axs.flatten(), images, captions):
  ax.imshow(img)
  ax.set_title(caption, loc='center', pad=20, y=-0.2)
  ax.axis('off')  # Hide axes

plt.tight_layout()
plt.show()
```

::: {.cell-output .cell-output-display}
![](template_files/figure-markdown/fig-images-output-1.png)
:::
::::

## Citations

This is a citation [@idv].

This is also a citation @idv.

------------------------------------------------------------------------

## Embed Video

::: {#video-intro .embed-video poster="resources/media/tank_tracks_on_the_ground_sky_reflecting.jpg" video="resources/media/sample.wmv" width="80%" x="0%"}
![](resources/media/tank_tracks_on_the_ground_sky_reflecting.jpg)
:::

------------------------------------------------------------------------

## Embed Video (URL + size)

<!-- To include youtube videos use the iframe URL for embedding -->

::: {#video-url .embed-video poster="resources/media/tank_tracks_on_the_ground_sky_reflecting.jpg" video="https://www.youtube.com/embed/_Sl8diqCAFw?list=PL4Gr5tOAPttJ247vzkv1ZbUEm_YtKLejH&t=1" width="80%" height="80%"}
![](resources/media/tank_tracks_on_the_ground_sky_reflecting.jpg)
:::

## References
