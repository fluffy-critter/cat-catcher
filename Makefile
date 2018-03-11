# ugh this is such a mess, maybe I should use cmake or scons or something

# itch.io target
TARGET=fluffy/cat-catcher

# game directory
SRC=src

# build directory
DEST=build

# build dependencies directory
DEPS=build_deps

# Application name
NAME=CATcher
BUNDLE_ID=biz.beesbuzz.CATcher

# LOVE version to fetch and build against
LOVE_VERSION=0.10.2

# Version of the game - whenever this changes, set a tag for v$(BASEVERSION) for the revision base
BASEVERSION=1.0

# Determine the full version string based on the tag
COMMITHASH=$(shell git rev-parse --short HEAD)
COMMITTIME=$(shell expr `git show -s --format=format:%at` - `git show -s --format=format:%at v$(BASEVERSION)`)
GAME_VERSION=$(BASEVERSION).$(COMMITTIME)-$(COMMITHASH)

GITSTATUS=$(shell git status --porcelain | grep -q . && echo "dirty" || echo "clean")

# supported publish channels
CHANNELS=love osx win32 win64

.PHONY: clean all run
.PHONY: publish publish-precheck publish-all
.PHONY: publish-status publish-wait
.PHONY: commit-check
.PHONY: love-bundle osx win32 win64 bundle-win32
.PHONY: submodules tests checks version
.PHONY: music

# necessary to expand the PUBLISH_CHANNELS variable for the publish rules
.SECONDEXPANSION:

# don't remove secondary files
.SECONDARY:

publish-dep=$(DEST)/.published-$(GAME_VERSION)_$(1)
PUBLISH_CHANNELS=$(foreach tgt,$(CHANNELS),$(call publish-dep,$(tgt)))

all: submodules checks tests love-bundle osx win32 win64 bundle-win32 staging

clean:
	rm -rf build

submodules:
	git submodule update --init --recursive

version:
	@echo "$(GAME_VERSION)"

publish-all: publish

publish: publish-precheck $$(PUBLISH_CHANNELS) publish-status
	@echo "Done publishing full build $(GAME_VERSION)"

publish-precheck: commit-check tests checks

publish-status:
	butler status $(TARGET)
	@echo "Current version: $(GAME_VERSION)"

publish-wait:
	@while butler status $(TARGET) | grep '•' ; do sleep 5 ; done

commit-check:
	@[ "$(GITSTATUS)" == "dirty" ] && echo "You have uncommitted changes" && exit 1 || exit 0

tests:
	@which love 1>/dev/null || (echo \
		"love (https://love2d.org/) must be on the path to run the unit tests" \
		&& false )
	love $(SRC) --cute-headless

checks:
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	find src -name '*.lua' | grep -v thirdparty | xargs luacheck -q

run: love-bundle
	love $(DEST)/love/$(NAME).love

music: $(patsubst raw_assets/wav/%.wav,src/sound/%.ogg,$(wildcard raw_assets/wav/*.wav))
src/sound/%.ogg: raw_assets/wav/%.wav
	oggenc $(^) -o $(@)

$(DEST)/.latest-change: $(shell find $(SRC) -type f)
	mkdir -p $(DEST)
	touch $(@)

staging: $(foreach tgt,$(CHANNELS),staging-$(tgt))

staging-love: love-bundle $(DEST)/.distfiles-$(GAME_VERSION)_love
staging-osx: osx $(DEST)/.distfiles-$(GAME_VERSION)_osx
staging-win32: win32 $(DEST)/.distfiles-$(GAME_VERSION)_win32
staging-win64: win64 $(DEST)/.distfiles-$(GAME_VERSION)_win64

$(DEST)/.distfiles-$(GAME_VERSION)_%: LICENSE $(wildcard distfiles/*)
	@echo $(DEST)/$(lastword $(subst _, ,$(@)))
	for i in $(^) ; do \
		sed 's/{VERSION}/$(GAME_VERSION)/g' $$i > $(DEST)/$(lastword $(subst _, ,$(@)))/$$(basename $$i) ; \
	done && \
	touch $(@)


$(DEST)/.published-$(GAME_VERSION)_%: staging-% $(DEST)/%/LICENSE
	butler push $(DEST)/$(lastword $(subst _, ,$(@))) $(TARGET):$(lastword $(subst _, ,$(@))) --userversion $(GAME_VERSION) && touch $(@)

# hacky way to inject the distfiles content
$(DEST)/%/LICENSE: $(DEST)/.distfiles-%-$(GAME_VERSION) LICENSE $(wildcard distfiles/*)
	@echo BUILDING: $(@)
	mkdir -p $(shell dirname $(@))
	for i in LICENSE distfiles/* ; do sed s/{VERSION}/$(GAME_VERSION)/g "$i" > $(shell dirname $(@))/$(shell basename "$i")
	touch $(DEST)/.distfiles-%-$(GAME_VERSION)

# download build-dependency stuff
$(DEPS)/love/%:
	@echo BUILDING: $(@)
	mkdir -p $(DEPS)/love
	curl -L -o $(@) https://bitbucket.org/rude/love/downloads/$(shell basename $(@))

# .love bundle
love-bundle: submodules $(DEST)/love/$(NAME).love music
$(DEST)/love/$(NAME).love: $(DEST)/.latest-change Makefile
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/love
	rm -f $(@)
	cd $(SRC) && zip -9r ../$(@) . -x 'test'
	printf "%s" "$(GAME_VERSION)" > $(DEST)/version
	zip -9j $(@) $(DEST)/version

# macOS version
osx: $(DEST)/osx/$(NAME).app
$(DEST)/osx/$(NAME).app: love-bundle $(wildcard osx/*) $(DEST)/deps/love.app
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/osx
	rm -rf $(@)
	cp -r "$(DEST)/deps/love.app" $(@) && \
	sed 's/{TITLE}/$(NAME)/;s/{BUNDLE_ID}/$(BUNDLE_ID)/;s/{VERSION}/$(GAME_VERSION)/g' osx/Info.plist > $(@)/Contents/Info.plist && \
	cp osx/*.icns $(@)/Contents/Resources/ && \
	cp $(DEST)/love/$(NAME).love $(@)/Contents/Resources

# OSX build dependencies
$(DEST)/deps/love.app: $(DEPS)/love/love-$(LOVE_VERSION)-macosx-x64.zip
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/deps && \
	unzip -d $(DEST)/deps $(^)
	touch $(@)

# Windows build dependencies
WIN32_ROOT=$(DEST)/deps/love-$(LOVE_VERSION)-win32
WIN64_ROOT=$(DEST)/deps/love-$(LOVE_VERSION)-win64

$(WIN32_ROOT)/love.exe: $(DEPS)/love/love-$(LOVE_VERSION)-win32.zip
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/deps/
	unzip -d $(DEST)/deps $(^)
	touch $(@)

$(WIN64_ROOT)/love.exe: $(DEPS)/love/love-$(LOVE_VERSION)-win64.zip
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/deps/
	unzip -d $(DEST)/deps $(^)
	touch $(@)

# Win32 version
win32: $(WIN32_ROOT)/love.exe $(DEST)/win32/$(NAME).exe
$(DEST)/win32/$(NAME).exe:$(WIN32_ROOT)/love.exe $(DEST)/love/$(NAME).love
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/win32
	cp -r $(wildcard $(WIN32_ROOT)/*.dll) $(DEST)/win32
	cat $(^) > $(@)

# Win64 version
win64: $(WIN64_ROOT)/love.exe $(DEST)/win64/$(NAME).exe
$(DEST)/win64/$(NAME).exe: $(WIN64_ROOT)/love.exe $(DEST)/love/$(NAME).love
	@echo BUILDING: $(@)
	mkdir -p $(DEST)/win64
	cp -r $(wildcard $(WIN64_ROOT)/*.dll) $(DEST)/win64
	cat $(^) > $(@)

WIN32_BUNDLE_FILENAME=catcher-win32-$(GAME_VERSION).zip
bundle-win32: $(DEST)/$(WIN32_BUNDLE_FILENAME)
$(DEST)/$(WIN32_BUNDLE_FILENAME): win32
	cd $(DEST)/win32 && zip -9r ../$(WIN32_BUNDLE_FILENAME) *
