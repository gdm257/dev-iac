# Conventions

## deploy/docker Compose files

变量插值语义（与 README TIP 一致）：

- `${VAR}` — required variable
- `${VAR:-}` — optional variable
- `${VAR:-default}` — optional variable with default

## 注释与文档

所有支持注释的文件保持零注释；仅当语义无法从命名与默认值推断时 MAY 加一行。

文档以可执行的命令和代码块为主，MUST 用示例说话，不写解释性段落。
