# GitHub Actions Secrets and Setup

The CI/CD workflows need private credentials. Add them as **GitHub Actions secrets**; do not commit them, paste them into issues or chats, or add them to ordinary repository variables.

## 1. Find the Android signing credentials

The Android release workflow needs the same signing key used for previous APK releases. The key is not stored in this repository; CI temporarily recreates it from a secret and deletes it after the build.

You need:

| Secret name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoding of the existing `.jks` or `.keystore` file |
| `ANDROID_KEYSTORE_PASSWORD` | Password for the keystore |
| `ANDROID_KEY_ALIAS` | Alias of the signing key inside the keystore |
| `ANDROID_KEY_PASSWORD` | Password for that key alias |

Use the original release keystore and passwords from the secure location where they were backed up. Do **not** create a new key for an app that already has releases: a different key generally cannot update an APK signed with the original key.

If you have the keystore but do not know its alias, use `keytool` from a JDK or Android Studio terminal; it will prompt for the password:

```powershell
keytool -list -v -keystore "C:\secure\path\upload-keystore.jks"
```

## 2. Encode the keystore on Windows

In PowerShell, replace the example path with the location of the existing keystore. This copies the Base64 value directly to the clipboard instead of printing it:

```powershell
$keystorePath = "C:\secure\path\upload-keystore.jks"
$keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
$keystoreBase64 = [Convert]::ToBase64String($keystoreBytes)
Set-Clipboard -Value $keystoreBase64
Remove-Variable keystoreBytes, keystoreBase64
```

Keep the clipboard private. Paste its contents into the `ANDROID_KEYSTORE_BASE64` secret in the next step, then clear the clipboard:

```powershell
Set-Clipboard -Value ""
```

## 3. Add Android secrets to GitHub environments

1. Open the repository on GitHub.
2. Go to **Settings → Environments**.
3. Create an environment named exactly `android-beta`.
4. Create another environment named exactly `android-production`.
5. For each environment, add the four Android secrets listed in Step 1:
   - Open the environment.
   - Under **Environment secrets**, choose **Add secret**.
   - Enter the exact secret name and value, then save.
6. Use the same keystore and passwords in both environments. That lets beta APKs install as upgrades over stable APKs. The workflows use separate environments so approval rules can protect when those credentials are used.
7. Add required reviewers to both environments, if that option is available for this repository. Require an approval before deployment.

The environment names must match the workflows: beta uses `android-beta`; stable releases use `android-production`. Missing secrets or a misspelled environment will make signing fail.

## 4. Create the OCR pull-request token

The OCR workflow uses a token named `TAFSIR_PR_TOKEN` to push its generated branch and open a review PR. A separate token allows normal PR checks to run on that branch.

1. On GitHub, open your profile menu and go to **Settings → Developer settings → Personal access tokens → Fine-grained tokens**.
2. Choose **Generate new token**.
3. Select this repository only (`quran-hafezi-imdadia`) and use a short expiration.
4. Grant repository permissions:
   - **Contents: Read and write**
   - **Pull requests: Read and write**
5. Generate and copy the token. Treat it as a password; you cannot retrieve its value later.
6. In the repository, go to **Settings → Secrets and variables → Actions → Repository secrets**.
7. Choose **New repository secret**, name it exactly `TAFSIR_PR_TOKEN`, paste the token, and save it.
8. Renew the token before it expires and update the repository secret.

Do not put the token in `FEATURE_BACKLOG.md`, source code, workflow YAML, or a terminal command that saves it in shell history.

## 5. Require checks and approvals

1. Go to **Settings → Branches** and add a protection rule for `main`.
2. Require pull requests before merging and require the relevant successful Actions checks, such as **Test & Build Android APK** and **Generate & Validate Web Bundle**.
3. Go to **Settings → Environments** and verify that `android-beta` and `android-production` require reviewer approval before accessing signing secrets.
4. Keep stable releases restricted to approved stable tags; use `vMAJOR.MINOR.PATCH-beta.N` for beta tags.

GitHub plan or repository settings may affect whether environment reviewers are available. If required reviewers are unavailable, protect signing secrets with the strongest available repository access controls and retain required PR checks.

## 6. Use the workflows

- **Pull request:** Android and relevant web checks run automatically.
- **Android beta:** update `pubspec.yaml` to the beta version, create and push a matching tag such as `v3.4.0-beta.1`, then approve the `android-beta` environment deployment. The tag must point to the source being built.
- **Android stable:** after beta acceptance, update the stable version, create and push a matching tag such as `v3.4.0`, then approve the `android-production` environment deployment.
- **OCR/tafsir:** manually run the OCR workflow. It validates the database and opens a PR for review instead of pushing data directly to `main`.

The app's Android version must match each release tag. For example, the beta tag `v3.4.0-beta.1` requires a matching `3.4.0-beta.1` version in `pubspec.yaml` (a `+buildNumber` suffix is allowed).

## Troubleshooting

- **Missing signing secret:** verify all four Android secrets exist in the exact environment used by the workflow.
- **Signing rejected or app cannot update:** verify the original keystore, alias, and both passwords. Do not substitute a newly generated keystore.
- **OCR workflow cannot push/open a PR:** verify `TAFSIR_PR_TOKEN` exists, has the listed permissions, and has not expired.
- **Workflow waits for approval:** approve the deployment through the environment review prompt in the Actions run.
