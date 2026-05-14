### Summary

Describe the kanagawa.wz documentation change.

### Documentation Changed

List the README, examples, contributing guide, issue templates, pull request
templates, or annotation docs changed by this pull request.

### Reader Impact

Explain who benefits from this documentation change:

- Users applying Kanagawa schemes in WezTerm.
- Users configuring appearance-aware switching.
- Contributors changing scheme data or application helpers.

### Examples Touched

```lua
-- scheme or appearance example changed by this pull request
```

### Behavior Change

- [ ] Documentation only
- [ ] Documents an existing behavior
- [ ] Documents a new behavior

If this documents a new behavior, link to the implementation pull request or
commit.

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

