fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios make_ipa

```sh
[bundle exec] fastlane ios make_ipa
```

ipaを生成

### ios upload_testFlight

```sh
[bundle exec] fastlane ios upload_testFlight
```

指定されたipaでTestFlight配信を行う

### ios release

```sh
[bundle exec] fastlane ios release
```

指定されたipaでApp Storeリリースを行う

### ios update_profile

```sh
[bundle exec] fastlane ios update_profile
```

指定されたipaでTestFlight配信を行う

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
