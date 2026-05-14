### Summary

Describe the new kanagawa.wz feature and the user-facing color scheme workflow
it enables.

### Motivation

Explain why this belongs in kanagawa.wz. Focus on Kanagawa scheme registration,
appearance-aware selection, WezTerm config application, or palette overrides.

### API Sketch

```lua
-- show intended scheme, registration, or apply_by_appearance usage
```

### Behavior

Describe how the feature behaves, including supported scheme names, appearance
handling, config fields changed, overrides, and failure cases.

### Compatibility

- [ ] Non-breaking
- [ ] Potentially breaking
- [ ] Breaking

If this is potentially breaking or breaking, explain the migration path.

### Tests

Describe the tests added or updated for this behavior.

### Documentation

Describe the README, examples, annotation, or template changes made for this
feature.

### Checklist

- [ ] The change is scoped to kanagawa.wz.
- [ ] Public API changes are documented, if applicable.
- [ ] Scheme registration or config-application behavior is covered by tests, if applicable.
- [ ] Existing scheme names remain compatible.
- [ ] Required checks pass:
  - [ ] `busted --verbose`
  - [ ] `luacheck .`
  - [ ] `stylua --check .`
  - [ ] `selene --display-style=quiet .`

