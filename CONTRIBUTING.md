# Contributing to Main Project

Thank you for your interest in contributing to Main Project! We welcome contributions from the community.

## Development Setup

Please follow the setup instructions in [README.md](README.md) to get the project running locally.

## Branching Strategy

We use a Git Flow-inspired branching model:

- `main`: Production-ready code, always deployable
- `develop`: Integration branch for features
- Feature branches: `feat/feature-name` (e.g., `feat/add-user-authentication`)
- Bug fix branches: `fix/bug-description` (e.g., `fix/login-validation-error`)
- Hotfix branches: `hotfix/critical-issue` (directly from main)

### Creating a Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feat/your-feature-name
```

## Pull Request Process

1. **Create a PR**: Open a pull request against the `develop` branch (or `main` for hotfixes)
2. **PR Template**: Fill out the PR template with:
   - Description of changes
   - Testing instructions
   - Screenshots (if UI changes)
   - Related issues
3. **Code Review**: At least one maintainer must approve
4. **CI Checks**: All CI checks must pass
5. **Merge**: Squash merge with descriptive commit message

### PR Template

```
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested the changes.

## Screenshots (if applicable)
Add screenshots to help reviewers understand UI changes.

## Related Issues
Fixes #123
```

## Code Standards

- Follow the linting rules defined in `analysis_options.yaml`
- Write tests for new features and bug fixes
- Use meaningful commit messages
- Keep PRs focused on a single feature or fix

## Commit Messages

Use conventional commit format:

- `feat: add user authentication`
- `fix: resolve login validation error`
- `docs: update API documentation`
- `refactor: simplify user service logic`

## Testing

- Run `flutter test` to execute unit tests
- Add tests for new functionality
- Ensure all tests pass before submitting PR

## Questions?

If you have questions about contributing, please open an issue or contact the maintainers.