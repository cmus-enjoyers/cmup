# ZmupZql installation

```bash
  git clone --depth 1 --single-branch https://github.com/cmus-enjoyers/cmup

  cd cmup/zig/cmup
  zig build -Doptimize=ReleaseFast install -p ~/.local
```

and install [zql syntax highlighting](https://github.com/cmus-enjoyers/tree-sitter-zql) (recommended)

# CmupC installation

```bash
  git clone --depth 1 --single-branch https://github.com/cmus-enjoyers/cmup

  cd cmup/cmup-c/

  gcc cmup.c -o ~/.local/bin
```
