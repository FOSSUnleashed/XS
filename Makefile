gen_headers = gen/buildinfo.hxx gen/git_date.hxx gen/git_hash.hxx gen/git_url.hxx
gen_source = gen/initial.cxx gen/sigmsgs.cxx

all: build/trashdump build/trash

clean:
	rm gen/*.?xx build/trash build/trashdump

build/trashdump: $(gen_headers) gen/sigmsgs.cxx
	# trashdump still needs this to build for some reason
	touch gen/initial.cxx
	# This command will fail because it will also try to build trash
	./build.sh || true
	# prevent make from thinking this is a good file
	rm gen/initial.cxx

build/trash: build/trashdump $(gen_headers) $(gen_source)
	./build.sh

gen/%:
	$(MAKE) -C gen $(subst gen/,,$@)
