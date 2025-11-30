## Docker Compose vs Docker Swarm

| Feature           | Docker Compose | Docker Swarm |
|-------------------|----------------|--------------|
| Env file          | ✓              | ✗            |
| Config management | ✗              | ✓            |
| Secrets management| ✗              | ✓            |
| Multi-node        | ✗              | ✓            |

> [!TIPS]
> It's recommended to use external secrets feature of doco-cd to replace env file.
