<div align="center">
  <img alt="Jots Icon" src="data/icons/default/hicolor/128.png" />
  <h1>Jots</h1>
  <h3>A simple, lightweight sticky notes application for the Linux desktop</h3>

  <a href="https://elementary.io">
    <img src="https://ellie-commons.github.io/community-badge.svg" alt="Made for elementary OS">
  </a>
  
  <span align="center">
    <img class="center" src="data/screenshots/spread.png" alt="Jots screenshot">
  </span>
</div>

<br/>

## 🦺 Installation & Compilation

Jots is distributed as a sandboxed Flatpak application:

* **Flathub**: [Download on Flathub](https://flathub.org/apps/io.github.comicdeed.jots)
* **AppCenter**: [Get it on AppCenter](https://appcenter.elementary.io/io.github.comicdeed.jots)
* **Local Build / Compilation**: Refer to the [Building Guide](docs/development/building.md) for native and sandbox compilation instructions.
* **Windows**: Basic experimental installers are available in the Releases section. Detailed MSYS2 build steps are available in the [Windows Build Guide](docs/development/windows.md).

<br/>

## ❓ Support & Discussions
* **Discussions**: Ask questions or discuss new features in the [GitHub Discussions tab](https://github.com/comicdeed/jots/discussions).
* **Issue Tracker**: Report bugs or suggest enhancements via the [Issues tab](https://github.com/comicdeed/jots/issues).

<br/>

## 💾 Notes Storage
All notes are serialized into a simple JSON array in `saved_state.json`. 

> [!NOTE]
> The JSON structure is an internal format and may change without notice as the application evolves. However, the application will always include automatic migrations to ensure your existing notes are safely upgraded during updates.

### Flatpak / Sandbox Storage Paths
If installed via Flathub or AppCenter, notes are saved inside the application sandbox:
`~/.var/app/io.github.comicdeed.jots/data/io.github.comicdeed.jots/saved_state.json`
