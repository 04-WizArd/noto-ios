# Ink — iOS Notes App

A native notes app for iPhone and iPad, built with SwiftUI and SwiftData, with a modern Liquid Glass interface.

> **Status: work in progress.** This is a portfolio project under active development. Features, design and structure may still change.

**Languages:** [English](#english) · [Français](#français)

---

## English

### Overview

Ink is a focused, offline-first notes app. Notes are stored locally with SwiftData. The interface separates **content** (notes drawn on solid surfaces) from **interaction** (floating Liquid Glass controls).

> **Naming:** the product is called **Ink**. The repository (`noto-ios`), the Xcode project, target and scheme (`Yportfolio`) and the bundle identifier keep their original internal names.

### Features

- **Create and edit notes:** a compose button opens a new note with a zoom transition. Each note has a title and a body, and edits are saved automatically through SwiftData.
- **Quick capture:** type a line on the home screen and send it to save it as a new note.
- **Automatic cleanup:** notes left empty (blank or whitespace only) are discarded when the editor closes and at launch.
- **Search:** case-insensitive, locale-aware search in titles and bodies.
- **Sorting:** by date modified, date created or title.
- **Filters:** *All* (with the note count), *Pinned*, and *Recent* (edited in the last 7 days).
- **Pinned notes (bookmarks):** pin from a card's corner, swipe actions, the context menu or the editor. Pinned notes always come first.
- **Featured deck:** the first three notes appear as a numbered, stacked card deck on the home screen.
- **List and gallery views:** a classic list, or a gallery with a regular layout (two tall cards, then one wide card).
- **Multi-selection:** select several notes or all of them, then delete them in one action after a confirmation prompt.
- **Sharing:** share a note as plain text from the editor.
- **Accent colours:** each note has an accent colour, picked at random when it is created.
- **Light and Dark Mode**, with surfaces, tints and shadows tuned for each.
- **Localization:** English and French (String Catalog).

### Design and accessibility

- **Liquid Glass UI:** floating glass dock, top control, search field, selection bar and editor action island, all on a shared 52 pt control grid.
- **Animations:** zoom navigation transitions, spring-based deck animations, symbol and numeric-text transitions, and haptic feedback for pin, delete, selection and capture.
- **Reduce Motion:** animations are simplified or turned off when it is enabled.
- **Dynamic Type:** sizes scale with `@ScaledMetric`. At accessibility text sizes, the gallery switches to a single column and the filter chips scroll horizontally.
- **VoiceOver:** labels, hints, custom actions, header and selected traits on the main controls and cards, plus the Large Content Viewer on the dock buttons.

### Architecture

The app uses a lightweight **MVVM** architecture:

- **Model:** `Note` is a SwiftData `@Model`. Small value types (`NoteSortOrder`, `NoteFilter`, `NoteAccent`, `NoteViewStyle`) hold the sorting, filtering and display logic, so it can be tested on its own.
- **ViewModel:** `NotesViewModel` (`@Observable`) handles every write that has a business rule: creating, capturing, editing timestamps, pinning, deleting, cleaning up empty notes, and saving explicitly. Persistence errors are logged with `OSLog` and shown in the UI.
- **Views:** views read data with `@Query` and edit it with `@Bindable`. A single `NotesViewModel` is created at launch and injected through the SwiftUI environment.
- **Design system:** spacing, radius, surface, typography and motion tokens are centralized in `DS`.

```
Yportfolio/
├── YportfolioApp.swift        # App entry point, ModelContainer, launch cleanup
├── ContentView.swift          # Home screen: state, filtering, search, navigation
├── Model/                     # Note (SwiftData), sort order, filter, accent, view style, preview data
├── ViewModels/                # NotesViewModel
├── Views/
│   ├── Home/                  # Header, featured deck, quick capture, top bar, bottom dock
│   ├── Controls/              # Glass islands, circle/pill buttons, card badges
│   ├── Editor/                # Editor action island
│   └── …                      # List, gallery, rows, cards, tiles, note editor
├── Styles/                    # Design tokens, button styles, gallery layout
└── Localizable.xcstrings      # English / French strings
YportfolioTests/               # Unit tests (Swift Testing)
```

### Tech stack

- Swift (Swift 5 language mode, `MainActor` default isolation)
- SwiftUI
- SwiftData
- Swift Testing
- OSLog

### Requirements

- Xcode with the iOS 26.5 SDK or later (developed with Xcode 27.2)
- iOS / iPadOS 26.5 or later
- No third-party dependencies

### Getting started

```bash
git clone https://github.com/04-WizArd/noto-ios.git
cd noto-ios
open Yportfolio.xcodeproj
```

In Xcode, select the **Yportfolio** scheme and an iPhone or iPad simulator, then press **⌘R**.

### Testing

The unit tests use **Swift Testing** and run against a fresh in-memory SwiftData store for each test. An injectable clock makes the date logic deterministic. They cover:

- note creation, quick capture, editing timestamps and persistence;
- pinning and unpinning;
- single, multiple and launch-time deletion of empty notes;
- sorting, pinned-first grouping and filters;
- model helpers (accent colours, content detection, share text);
- error reporting.

Run them in Xcode with **⌘U**, or from the command line:

```bash
xcodebuild test \
  -project Yportfolio.xcodeproj \
  -scheme Yportfolio \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Screenshots

Screenshots are not in the repository yet. They will be added to a `docs/screenshots/` folder and linked here.

### Roadmap

- Advanced filters sheet (a placeholder exists, but it can't be opened yet)
- A recovery and migration strategy for the SwiftData store
- UI tests
- Screenshots and a short demo

### License

Released under the [MIT License](LICENSE). © 2026 Jordi Mukeba.

---

## Français

### Présentation

Ink est une application de notes simple et native, qui fonctionne hors ligne. Les notes sont stockées localement avec SwiftData. L’interface sépare le **contenu** (les notes, sur des surfaces opaques) de l’**interaction** (des commandes flottantes en Liquid Glass).

> **Nommage :** le produit s’appelle **Ink**. Le dépôt (`noto-ios`), le projet, la cible et le schéma Xcode (`Yportfolio`) ainsi que l’identifiant de bundle gardent leurs noms internes d’origine.

### Fonctionnalités

- **Création et édition de notes :** le bouton de création ouvre une nouvelle note avec une transition zoom. Chaque note a un titre et un corps, et les modifications sont enregistrées automatiquement via SwiftData.
- **Saisie rapide :** tapez une ligne sur l’écran d’accueil et envoyez-la pour l’enregistrer comme nouvelle note.
- **Nettoyage automatique :** les notes restées vides (ou contenant seulement des espaces) sont supprimées à la fermeture de l’éditeur et au lancement.
- **Recherche :** dans les titres et le contenu, insensible à la casse et adaptée à la langue.
- **Tri :** par date de modification, date de création ou titre.
- **Filtres :** *Toutes* (avec le nombre de notes), *Épinglées* et *Récentes* (modifiées ces 7 derniers jours).
- **Notes épinglées (signets) :** épinglage depuis le coin d’une carte, par balayage, par le menu contextuel ou depuis l’éditeur. Les notes épinglées sont toujours affichées en premier.
- **Pile de notes à la une :** les trois premières notes apparaissent sur l’accueil sous forme de cartes numérotées et empilées.
- **Vues liste et galerie :** une liste classique, ou une galerie à disposition régulière (deux cartes hautes, puis une carte large).
- **Sélection multiple :** sélectionnez plusieurs notes, ou toutes, puis supprimez-les en une seule fois après confirmation.
- **Partage :** partage d’une note en texte brut depuis l’éditeur.
- **Couleurs d’accent :** chaque note a une couleur d’accent, choisie au hasard à sa création.
- **Modes clair et sombre**, avec des surfaces, teintes et ombres adaptées à chacun.
- **Localisation :** anglais et français (String Catalog).

### Design et accessibilité

- **Interface Liquid Glass :** dock flottant, commande supérieure, champ de recherche, barre de sélection et barre d’actions de l’éditeur, tous alignés sur une grille de commandes commune de 52 pt.
- **Animations :** transitions de navigation zoom, animations de la pile à ressort, transitions de symboles et de chiffres, et retours haptiques pour l’épinglage, la suppression, la sélection et la saisie rapide.
- **Réduire les animations :** les animations sont simplifiées ou désactivées quand ce réglage est activé.
- **Dynamic Type :** les tailles s’adaptent grâce à `@ScaledMetric`. Aux tailles de texte d’accessibilité, la galerie passe sur une seule colonne et les filtres défilent horizontalement.
- **VoiceOver :** libellés, indications, actions personnalisées et traits (en-tête, sélection) sur les commandes et cartes principales, ainsi que la loupe de contenu (Large Content Viewer) sur les boutons du dock.

### Architecture

L’application suit une architecture **MVVM** légère :

- **Modèle :** `Note` est un `@Model` SwiftData. De petits types valeur (`NoteSortOrder`, `NoteFilter`, `NoteAccent`, `NoteViewStyle`) contiennent la logique de tri, de filtrage et d’affichage, ce qui permet de la tester séparément.
- **ViewModel :** `NotesViewModel` (`@Observable`) gère toutes les écritures soumises à une règle métier : création, saisie rapide, dates de modification, épinglage, suppression, nettoyage des notes vides et enregistrement explicite. Les erreurs de persistance sont journalisées avec `OSLog` et affichées dans l’interface.
- **Vues :** les vues lisent les données avec `@Query` et les modifient avec `@Bindable`. Un seul `NotesViewModel` est créé au lancement et transmis par l’environnement SwiftUI.
- **Design system :** les valeurs d’espacement, de rayon, de surface, de typographie et d’animation sont regroupées dans `DS`.

La structure du projet est décrite dans la [section anglaise](#architecture).

### Stack technique

- Swift (mode de langage Swift 5, isolation `MainActor` par défaut)
- SwiftUI
- SwiftData
- Swift Testing
- OSLog

### Prérequis

- Xcode avec le SDK iOS 26.5 ou plus récent (développé avec Xcode 27.2)
- iOS / iPadOS 26.5 ou plus récent
- Aucune dépendance tierce

### Installation

```bash
git clone https://github.com/04-WizArd/noto-ios.git
cd noto-ios
open Yportfolio.xcodeproj
```

Dans Xcode, choisissez le schéma **Yportfolio** et un simulateur iPhone ou iPad, puis appuyez sur **⌘R**.

### Tests

Les tests unitaires utilisent **Swift Testing**. Chaque test s’exécute sur un nouveau store SwiftData en mémoire, et une horloge injectable rend la logique des dates prévisible. Ils couvrent :

- la création, la saisie rapide, les dates de modification et la persistance ;
- l’épinglage et le désépinglage ;
- la suppression simple, multiple, et celle des notes vides au lancement ;
- le tri, le regroupement des notes épinglées et les filtres ;
- les fonctions utilitaires du modèle (couleurs d’accent, détection du contenu, texte de partage) ;
- la remontée des erreurs.

Lancez-les dans Xcode avec **⌘U**, ou en ligne de commande avec la commande `xcodebuild test` donnée dans la [section anglaise](#testing).

### Captures d’écran

Les captures d’écran ne sont pas encore dans le dépôt. Elles seront ajoutées dans un dossier `docs/screenshots/` et liées ici.

### Feuille de route

- Feuille de filtres avancés (un écran provisoire existe, mais il n’est pas encore accessible)
- Une stratégie de récupération et de migration du store SwiftData
- Tests d’interface (UI tests)
- Captures d’écran et courte démo

### Licence

Distribué sous [licence MIT](LICENSE). © 2026 Jordi Mukeba.
