# exam-points

A Quarto extension for automatic points management in exams and assignments.

## Features

- Add points to section headings with the `{.points=X}` attribute
- Automatically appends "(X Point)" / "(X Points)" to headings in the rendered document
- Validates that `exam.points-total` in the YAML header matches the sum of all individual task points
- Supports included files via `{{< include file.qmd >}}`
- Clear warnings on mismatch (console + optional callout box in document)

> [!TIP]
> **Localization**: Set `lang:` in your document's YAML header to get localized console messages.
> The following languages are supported: `en` *(default)*, `de`, `fr`, `it`, `es`, `nl`, `pl` and `ru`.
>
> Example:
> ```yaml
> ---
> lang: de
> exam:
>   points-total: 60
> ---
> ```

### Console output examples

When the declared total matches the sum of all tasks:

```
[exam-points-filter] Total points (10) match the sum of all subquestions ✓
```


When there is a mismatch (e.g. `points-total: 12` but tasks sum to `10`):

```
WARNING [exam-points-filter] exam.points-total is 12, but total points from tasks are 10.
```



## Installation

```
quarto add marcoduesentrieb/exam-points
```

## Usage

Add the following to your `_quarto.yml`:

```
filters:
  - exam-points
```

Then in your `.qmd` file:

```
---
title: "Electronics Exam"
exam:
  points-total: 60
  render-warning: true
---
```

### Task Example

```
### Exercise 1 {.points=15}

Solve the following equation...
```

This will be rendered as:

**Exercise 1 (15 points)**

Solve the following equation ...

## Configuration Options

| Option                | Type            | Description                                                                 | Default |
|-----------------------|-----------------|-----------------------------------------------------------------------------|---------|
| `points-total`        | number          | Total points of the exam                                                    | -       |
| `render-warning`      | boolean         | Show warning if points don't match                                          | `true`  |
| `points-label`        | string or array | Custom label used for point suffix; string = same label for singular/plural, array = `[singular, plural]` | `points` |

Example:

```
exam:
  points-total: 60
  render-warning: true
  points-label: ["punto","puntos"]
```

This will render headings like **Ejercicio 1 (1 punto)** when the point value is singular and **Ejercicio 1 (15 puntos)** when plural.

## License

MIT License — see the [LICENSE](LICENSE) file for details.
