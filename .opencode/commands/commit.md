Review the current git diff.

Determine whether the changes represent exactly one logical change.

If the working tree contains unrelated changes, DO NOT commit.

Verify:

flutter analyze
flutter test

Before generating the commit:

1. Verify the implementation has passed review.
2. Verify the implementation has passed verification.
3. Confirm only one logical change is present.

If review has a BLOCKER or IMPORTANT issue, do not recommend committing.

If verification fails, do not recommend committing.
Generate an appropriate Conventional Commit message.

Show:

1. Commit message
2. Files included
3. Tests executed
4. Verification result

Do not commit until the user explicitly approves.