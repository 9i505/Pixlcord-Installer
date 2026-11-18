.PHONY: all clean build help

PLATFORM 	?= $(shell go env GOOS)
ARCH		?= $(shell go env GOARCH)

VERSION 	?= $(shell git describe --tags --abbrev=0)
HASH 		:= $(shell git rev-parse --short HEAD | xargs)

RESOURCE_VERSION := git-tag
ifeq ($(VERSION),Unknown)
RESOURCE_VERSION := 0.0.0
endif

IDENTITY 	?= -

GUI 		?= 0
DMG 		?= 0
WAYLAND 	?= 0

LDFLAGS 	?= -s -w -X 'vencordinstaller/buildinfo.InstallerGitHash=$(HASH)' -X 'vencordinstaller/buildinfo.InstallerTag=$(VERSION)'
TAGS    	?= static
CGO 		:= 0
POSTFIX 	:=

ifeq ($(PLATFORM),windows)
ifeq ($(GUI),0)
LDFLAGS 	+= -extldflags=-static
else
LDFLAGS 	+= -H=windowsgui -extldflags=-static
endif
endif

ifeq ($(GUI),0)
TAGS 		+= cli
POSTFIX 	:= Cli
else
CGO 		:= 1
ifeq ($(WAYLAND),1)
TAGS 		+= wayland
endif
endif

MACOS_ARCHS := $(ARCH)
WINDOWS_BINARY := PixlcordInstaller$(POSTFIX).exe
ifeq ($(GUI),1)
WINDOWS_BINARY := PixlcordInstaller.exe
endif
ifeq ($(ARCH),universal)
MACOS_ARCHS := amd64 arm64
endif

all: build

build:
	mkdir -p build

ifeq ($(PLATFORM),darwin)
	for arch in $(MACOS_ARCHS); do \
		MACOSX_DEPLOYMENT_TARGET=10.13 \
		CGO_ENABLED=$(CGO) \
		GOOS=$(PLATFORM) \
		GOARCH=$$arch \
		go build \
			-v \
			-tags "$(TAGS)" \
			-ldflags "$(LDFLAGS)" \
			-o build/installer-$$arch; \
	done
ifeq ($(ARCH),universal)
	lipo -create \
		build/installer-amd64 \
		build/installer-arm64 \
		-output build/installer-universal
	rm build/installer-amd64 build/installer-arm64
endif
ifeq ($(GUI),1)
	cp -R macos/PixlcordInstaller.app build/PixlcordInstaller.app
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" build/PixlcordInstaller.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(HASH)" build/PixlcordInstaller.app/Contents/Info.plist
ifeq ($(ARCH),universal)
	mv build/installer-universal build/PixlcordInstaller.app/Contents/MacOS/PixlcordInstaller
else
	mv build/installer-$(ARCH) build/PixlcordInstaller.app/Contents/MacOS/PixlcordInstaller
endif
	codesign --deep --force --options runtime --sign "$(IDENTITY)" build/PixlcordInstaller.app
ifeq ($(DMG),1)
ifeq ($(shell command -v create-dmg 2>/dev/null),)
	$(error create-dmg is not installed)
endif
	create-dmg \
		--volname "Pixlcord Installer" \
		--volicon macos/dmg.icns \
		--background "macos/background.png" \
		--window-pos 200 120 \
		--window-size 510 340 \
		--icon-size 100 \
		--icon PixlcordInstaller.app 160 155 \
		--hide-extension PixlcordInstaller.app \
		--app-drop-link 350 155 \
		build/PixlcordInstaller.dmg \
		build/PixlcordInstaller.app
endif
else
	mv build/installer-$(ARCH) build/PixlcordInstallerCli-$(PLATFORM)
endif

else ifeq ($(PLATFORM),windows)
	export GOROOT=/mingw64/lib/go
	export GOPATH=/mingw64

	go-winres make --product-version "$(RESOURCE_VERSION)"
	CGO_ENABLED=$(CGO) GOOS=$(PLATFORM) GOARCH=$(ARCH) \
		go build -v -tags "$(TAGS)" \
		-ldflags "$(LDFLAGS)" \
		-o build/$(WINDOWS_BINARY)

else
	CGO_ENABLED=$(CGO) GOOS=$(PLATFORM) GOARCH=$(ARCH) go build \
		-v \
		-tags "$(TAGS)" \
		-ldflags "$(LDFLAGS)" \
		-o build/PixlcordInstaller$(POSTFIX)-$(PLATFORM)
	chmod +x build/PixlcordInstaller$(POSTFIX)-$(PLATFORM)
endif

clean:
	rm -rf build

help:
	@printf '%s\n' \
		'Usage: make <target> [OPTIONS]' \
		'' \
		'Targets:' \
		'  help     Show this help page' \
		'  build    Build the project (default)' \
		'  clean    Remove build artifacts' \
		'' \
		'Options:' \
		'  GUI=1       Build with GUI support' \
		'  DMG=1       Build DMG for macOS' \
		'  WAYLAND=1        Build with Wayland support for Linux' \
		'  PLATFORM=<os>    Target platform (darwin, windows, linux)' \
		'  ARCH=<arch>      Target architecture (amd64, arm64, 386, universal (macOS only))' \
		'  IDENTITY=<id>    Code signing identity for macOS (default: -)' \
		'  VERSION=<ver>    Version string (default: latest git tag)' \
		'' \
		'Examples:' \
		'  make clean' \
		'  make PLATFORM=universal GUI=1' \
		'  make PLATFORM=linux ARCH=amd64' \
		'  make GUI=1 VERSION="1.0.0"'
