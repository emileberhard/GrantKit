default:
    @just --list

test:
    swift test --jobs 4

build-ios:
    xcodebuild -quiet -scheme GrantKit -configuration Release -destination 'generic/platform=iOS' -derivedDataPath .local/ios-build CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build

demo:
    swift run --jobs 4 GrantKitDemo
