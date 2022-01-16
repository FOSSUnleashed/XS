

all: build/trashdump build/trash

clean:
	rm gen/*.?xx build/trash build/trashdump

build/trashdump:
	# This command will fail because it will also try to build trash
	./build.sh || true
	# This file is not built correctly and will break the rest of the build
	rm gen/initial.cxx

build/trash: build/trashdump gen/initial.cxx
	./build.sh

gen/initial.cxx:
	$(MAKE) -C gen
