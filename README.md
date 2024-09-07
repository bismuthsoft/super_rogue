# Super Rogue

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

*(Not [that][original-super-rogue] super rogue!)*

Inspired by [SUPERHOT][superhot].

[superhot]: https://superhotgame.com/
[original-super-rogue]: https://www.roguebasin.com/index.php/Super-Rogue

## Playing

### Online

Each release is automatically published to [bismuthsoft.github.io/super_rogue][web].

[web]: https://bismuthsoft.github.io/super_rogue/

### Pre-built for Linux, Windows

See our [releases page](https://github.com/bismuthsoft/super_rogue/releases) for downloads targeting Windows, Linux, and more!

*(Mac users, please consider downloading the `.love` file or playing [the web version][web].)*

### Run natively from source

Install [LÖVE (love2d)][love2d].  Then run:

```bash
# From the super-rogue/ directory...
love src
```

Or if you have nix (non-NixOS users need [nixGL][nixGL]):

```bash
nix run .#super_rogue.desktop
```

[love2d]: https://love2d.org/
[nixGL]: https://github.com/nix-community/nixGL

### Run in-browser from source

```bash
nix run .#super_rogue.web.serve
```

Visit http://localhost:8080/

## Contributing

All commits must pass [pre-commit][pre-commit] checks.  Install pre-commit from
your OS package manager then run `pre-commit install`.  The next time that `git
commit` runs, the pre-commit hook will also run its checks.

We use a standard GitHub Pull Request workflow.

[pre-commit]: https://pre-commit.com/

### Running tests

```bash
nix run .#super_rogue.test
```


### Restart game on code change

To run tests and run the desktop version of the game upon code change, try this commad.

```
find src | entr -r sh -c 'nix run .#super_rogue.test && nix run .#super_rogue.desktop'
```
