# Contributing to moonbit-wasmkit

Thank you for your interest in contributing to `moonbit-wasmkit`!

## Code Guidelines

1. **Pure MoonBit Requirement**: All core logic must be written in 100% pure MoonBit code without external C or JS foreign function interfaces.
2. **Toolchain Compliance**: Keep the code clean under the latest stable MoonBit toolchain. Local changes should pass `moon fmt --check`, `moon check --deny-warn`, `moon check --target all --deny-warn`, `moon info`, and both default and native tests.
3. **Commit Messages**: Follow conventional commit guidelines:
   - `feat(scope): ...`
   - `fix(scope): ...`
   - `test(scope): ...`
   - `docs(scope): ...`
   - `chore(scope): ...`

## Workflow

1. Fork the repository on GitHub.
2. Create your feature branch (`git checkout -b feat/my-new-feature`).
3. Ensure all tests pass (`moon test --deny-warn`).
4. Verify the native target and coverage when changing parser or CLI behavior (`moon test --target native --deny-warn --enable-coverage`).
5. Format code before committing (`moon fmt`).
6. Push to your branch and open a Pull Request.
