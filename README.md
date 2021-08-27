# rpp

An approach to preprocessing R code.

## Goals

The purpose of this project is to provide infrastructure that helps generating the files in the `R/` directory in a package, either from other sources, or inline.
Applications include:

- True zero-cost assertions
- True zero-cost logging
- Verbatim code inlining and expansion to simplify metaprogramming
- Static type annotations

## Location of the "source of truth"

### Inline

Works for assertions and logging.

Prerequisite: we don't add or remove extra lines.

Pros: doesn't need any extra files

Cons: transformation must be bidirectional (or at least work in the reverse way)

### Parallel directory

Required for inlining/expansion and static type annotations.

Pros: Works for all cases

Cons: Entirely new infrastructure

## Constraints

1. At any point in time, the code stored in version control should reflect the state most useful during *production*.
    - Rationale: `devtools::install_github()` should "just work" and give you a package that you can already use.
3. Ideally, the transformations occur during the following steps:
    - `devtools::document()`: from parallel directory to `R/`, and also prepare the inline code for production
    - `pkgload::load_all()`: this seems the most challenging part, do we need a hook into `load_all()` ?

    No transformation occurs during installation or execution time of the target package!
3. A no-op transformation should be fast.
    When transforming the same code twice, the second transformation should be instant.
    This is important for rapid development cycles.
4. Transformations should be pluggable, it should be easy to contribute plugins that add new transformations not considered yet
5. Package developers/contributors should get a clear error message if e.g. rpp is not installed
6. If files are generated, they should receive a "read-only" label that's picked up (at least) by RStudio; maybe it's worth marking the generated files as read-only too?