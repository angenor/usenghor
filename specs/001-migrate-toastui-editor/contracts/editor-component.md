# Contract: Composant Éditeur TOAST UI

## Interface du composant Vue

### Props

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | `string` | `''` | Contenu Markdown (v-model) |
| `initialEditType` | `'wysiwyg' \| 'markdown'` | `'wysiwyg'` | Mode d'édition initial |
| `height` | `string` | `'400px'` | Hauteur de l'éditeur |
| `placeholder` | `string` | `''` | Texte placeholder |
| `language` | `string` | `'fr-FR'` | Langue de l'interface |
| `direction` | `'ltr' \| 'rtl'` | `'ltr'` | Direction du texte |
| `disabled` | `boolean` | `false` | Éditeur en lecture seule |

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | `string` (Markdown) | Émis à chaque changement de contenu |
| `update:html` | `string` (HTML) | Émis à chaque changement, version HTML |
| `ready` | `void` | Émis quand l'éditeur est initialisé |
| `image-upload` | `{ blob: Blob, callback: (url: string) => void }` | Émis pour l'upload d'image |

### Expose (ref template)

| Méthode | Signature | Description |
|---------|-----------|-------------|
| `getHTML()` | `() => string` | Retourne le contenu HTML |
| `getMarkdown()` | `() => string` | Retourne le contenu Markdown |
| `setHTML(html)` | `(html: string) => void` | Définit le contenu depuis du HTML |
| `setMarkdown(md)` | `(md: string) => void` | Définit le contenu depuis du Markdown |
| `focus()` | `() => void` | Focus sur l'éditeur |
| `clear()` | `() => void` | Efface le contenu |

---

## Composable useToastUIEditor

### Interface

```typescript
interface UseToastUIEditorReturn {
  html: Ref<string>
  markdown: Ref<string>
  setContent(html: string, md: string): void
  clearContent(): void
  hasContent: ComputedRef<boolean>
  getPlainText(): string
  toJSON(): string    // Sérialise { html, markdown } en JSON
  fromJSON(json: string): void  // Désérialise depuis JSON
}
```

---

## Composant Renderer

### Props

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `html` | `string` | `''` | Contenu HTML à afficher |
| `class` | `string` | `''` | Classes CSS additionnelles |

### Comportement
- Rendu via `v-html` avec les classes Tailwind `prose dark:prose-invert`
- Post-traitement des liens : ajout `target="_blank"` et `rel="noopener noreferrer"`
- Support dark mode automatique via les classes prose de Tailwind
