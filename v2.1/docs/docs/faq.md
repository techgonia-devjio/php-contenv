# FAQ

**Q: Why split build vs runtime scripts?**  
A: Keeps final images small and free of compilers/headers. More reproducible.

**Q: Can I run multiple profiles at once?**  
A: Technically yes, but they bind the same port by default. The design assumes **one profile at a time**.

**Q: Do I need Node?**  
A: Only if your app uses an asset pipeline. Toggle it off to keep images smaller.

**Q: Can I persist shell history across projects?**  
A: We don’t enable that by default to avoid mixing histories. You can bind-mount `~/.bash_history` if you want, per project.

**Q: How do I change PHP version?**  
A: Swap the base tag in the Dockerfile path (e.g., `php/8.3/...`). You already have directories for 8.2/8.3/8.4.