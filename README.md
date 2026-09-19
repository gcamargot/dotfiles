# DevOps Dotfiles (macOS & Linux)

Repositorio de configuraciones para DevOps y desarrollo, compatible entre macOS (iTerm + Zsh) y Linux (Ghostty / herdr + Bash).

---

## Estructura del Repositorio

```text
dotfiles/
|-- .github/workflows/
|   `-- ci.yml           # Pipeline de CI (ShellCheck, sintaxis bash/zsh, nvim headless)
|-- .aliases             # Aliases compartidos compatibles con Bash y Zsh
|-- .bashrc              # Configuracion para Linux (Bash)
|-- .zshrc               # Configuracion para macOS (Zsh + Oh-My-Zsh)
|-- .tmux.conf           # Configuracion de Tmux (modo vi, mouse, escape rapido)
|-- .config/
|   `-- nvim/            # Configuracion completa de Neovim
|-- ssh/
|   `-- config.example   # Plantilla segura para ~/.ssh/config (sin credenciales)
|-- install.sh           # Script de instalacion con backups y modo --dry-run
|-- tests/
|   `-- test.sh          # Suite de pruebas automatizadas locales
`-- .gitignore           # Exclusion de claves, tokens, secretos e historiales
```

---

## Aliases y Utilidades

Los aliases en `.aliases` estan disponibles tanto en Bash como en Zsh:

* Kubernetes & Kubecolor:
  * k: kubectl (usa kubecolor si esta instalado)
  * kgp: kubectl get pods
  * kgpo: kubectl get pods -o wide
  * kgps: kubectl get pods --all-namespaces
  * kgns: kubectl get namespaces
  * kgn: kubectl get nodes
  * kgno: kubectl get nodes -o wide
  * kdp: kubectl describe pod
  * kl: kubectl logs
  * kvs: kubectl view-secret
* Kubeswitch (Switcher):
  * sw: switch
  * ns: switch namespace
* Editor & Git:
  * vi: nvim
  * gs: git status -sb
  * gd: git diff
  * gl: git log en una linea

---

## Instalacion

### 1. Clonar el repositorio
```bash
git clone <URL_DEL_REPO> ~/dotfiles
cd ~/dotfiles
```

### 2. Simular instalacion (Dry Run)
Para revisar que enlaces y respaldos se crearian sin modificar archivos:
```bash
./install.sh --dry-run
```

### 3. Instalar
Crea enlaces simbolicos a $HOME. Si ya existen archivos con el mismo nombre, se respaldan en ~/.dotfiles_backup_<fecha>/:
```bash
./install.sh
```

---

## Personalizaciones Locales

Cada shell carga opcionalmente un archivo local (ignorado por git) para configuraciones especificas de la maquina o tokens privados:

* ~/.aliases.local: Aliases exclusivos de la maquina
* ~/.bashrc.local: Variables o configs exclusivas de Bash
* ~/.zshrc.local: Variables o configs exclusivas de Zsh

---

## Pruebas y Validacion (CI)

Ejecutar la suite de pruebas local:
```bash
./tests/test.sh
```

El flujo de GitHub Actions (.github/workflows/ci.yml) verifica:
1. ShellCheck en scripts shell.
2. Validacion de sintaxis con "bash -n" y "zsh -n".
3. Carga limpia de Neovim en modo headless.
4. Prueba de ejecucion del instalador y creacion de enlaces simbolicos.
