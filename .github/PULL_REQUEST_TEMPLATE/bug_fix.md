### Summary

Describe the bug fixed in kanagawa.wz and the user-visible scheme or config
behavior that changed.

### Reproduction

Provide the smallest setup that reproduced the issue.

```lua
-- scheme registration or config application that reproduced the bug
```

### Root Cause

Explain why scheme resolution, palette data, appearance matching, overrides, or
config application was wrong.

### Fix

Describe the implementation change and why it fixes the problem.

### Regression Test

Describe the regression test added or updated.

### Compatibility Impact

- [ ] Non-breaking
- [ ] Potentially breaking
- [ ] Breaking

If this changes behavior intentionally, explain why the new behavior is correct.

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

