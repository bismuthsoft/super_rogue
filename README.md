# Super Rogue

*(Not [that][original-super-rogue] super rogue!)*

Inspired by [SUPERHOT][superhot].

[superhot]: https://superhotgame.com/
[original-super-rogue]: https://www.roguebasin.com/index.php/Super-Rogue

## Playing

### Run from source

Install [LÖVE (love2d)][love2d].  Then run:

```bash
# From the super-rogue/ directory...
love src
```

[love2d]: https://love2d.org/

## Contributing

All commits must pass [pre-commit][pre-commit] checks.  Install pre-commit from
your OS package manager then run `pre-commit install`.  The next time that `git
commit` runs, the pre-commit hook will also run its checks.

We use a standard GitHub Pull Request workflow.

[pre-commit]: https://pre-commit.com/
