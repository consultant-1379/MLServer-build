# mlserver_tensorflow

Custom MLServer runtime for Tensorflow Models


# Dependency versions Management

MLServer runtimes recommend usage of poetry to manage dependency versions, but Poetry does not give an option to pin transitive dependency versions.

Since we want to reuse same versions for transitive dependency packages brought by MLServer, we have to come up with an alternate solution to pin transitve dependency versions.

This runtime uses pyproject.toml with a constraints file obtained from MLServer release to pin dependency package versions to the exact versions used in a MLServer release.

Direct dependencies are defined in requirements.txt which is also referenced in pyproject.toml. Versions for these dependencies and their transitive dependencies is determined by using a constraints file.

bob rule: build.generate-constraints-file can be used to generate the constraints file


