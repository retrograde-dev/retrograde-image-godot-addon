# Retrograde Image Godot Addon

## Installation

Clone or download the repo to **res://addons/retrograde\_image** and enable it in your project settings.

## Use

Place your retrograde input templates and retrograde\_image.json somewhere in your project.

This directory should be excluded when exporting.

From the Retrograde tab, add your retrograde\_image.json to the configurations list.

Once added you will be able to select which inputs/outputs/theme/path you wish to use when generating your images.

Once configured press the **Generate Images** button.

## Input Paths

Your input template paths should be relative to your retrograde\_image.json file.

## Output Paths

The resulting output path will be **addon configuration path** + **retrograde\_image.json output path** + **retrograde\_image.json output config path**.

Path separators will be cleaned between joins.

If your retrograde\_image.json output path starts with './' it will be converted to '/'.

The resulting path will always start with res:// so it cannot be used to output images outside your Godot project.

If **Ignore Output Path** is checked, the **retrograde\_image.json output path** will not be appended.

If **Ignore Output Config Path** is checked, the **retrograde\_image.json output config path** will not be appended.

The **addon configuration path** can contain variable codes. This allows you full control over the output path for the selected output configuration.

ex. res://assets/inputs/[[input]]/[[variant]]

A full list can be found in the [Retrograde Image Documentation](https://github.com/retrograde-dev/retrograde-image?tab=readme-ov-file#available-variables).
