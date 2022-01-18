gen_headers = gen/buildinfo.hxx gen/git_date.hxx gen/git_hash.hxx gen/git_url.hxx
gen_source = gen/initial.cxx gen/sigmsgs.cxx

YACC = bison

CXXFLAGS ?= -Wall -Wextra

INCLUDE = -Isrc -Igen
LIBS = -lgc -lgccpp -lreadline -lffi
SOURCES = src/access.cxx src/closure.cxx src/conv.cxx src/eval.cxx src/fd.cxx src/glob.cxx src/glom.cxx src/heredoc.cxx src/input.cxx src/list.cxx src/main.cxx src/match.cxx src/opt.cxx src/prim-ctl.cxx src/prim.cxx src/prim-etc.cxx src/prim-io.cxx src/prim-rel.cxx src/prim-sys.cxx src/print.cxx src/proc.cxx src/signal.cxx src/split.cxx src/status.cxx src/str.cxx src/syntax.cxx src/term.cxx src/token.cxx src/tree.cxx src/util.cxx src/var.cxx src/version.cxx src/buildinfo.cxx
OBJECTS = $(patsubst src/%.cxx,build/%.o,$(SOURCES))
ALL_OBJECTS = $(OBJECTS) build/sigmsgs.o build/parse.o

.PHONY: clean all
all: build/trash

clean:
	rm -rf build gen

gen/ build/:
	mkdir -p $@

#build/trashdump: $(gen_headers) gen/sigmsgs.cxx
#	# trashdump still needs this to build for some reason
#	touch gen/initial.cxx
#	# This command will fail because it will also try to build trash
#	./build.sh || true
#	# prevent make from thinking this is a good file
#	rm gen/initial.cxx

#build/trash: build/trashdump $(gen_headers) $(gen_source)
#	./build.sh

build/version.o : gen/git_date.hxx gen/git_hash.hxx gen/git_url.hxx
build/buildinfo.o : gen/buildinfo.hxx
build/input.o build/token.o build/syntax.o :  gen/parse.tab.hxx

$(OBJECTS): build/%.o : src/%.cxx | build/
	$(CXX) -c $(CXXFLAGS) $(INCLUDE) $< -o $@

build/sigmsgs.o: gen/sigmsgs.cxx | build/
	$(CXX) -c $(CXXFLAGS) $(INCLUDE) $< -o $@

build/parse.o: gen/parse.tab.cxx | build/
	$(CXX) -c $(CXXFLAGS) $(INCLUDE) $< -o $@

build/trashdump: src/dump.cxx $(ALL_OBJECTS) | build/
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

build/trash: gen/initial.cxx $(ALL_OBJECTS) | build/
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

gen/parse.tab.cxx gen/parse.tab.hxx: src/parse.yxx | gen/
	$(YACC) -d -o gen/parse.tab.cxx $<

gen/buildinfo.hxx: | gen/
	cd gen && sh ../generators/buildinfo.sh

gen/git_date.hxx: | gen/
	cd gen && sh ../generators/git_date.sh

gen/git_hash.hxx: | gen/
	cd gen && sh ../generators/git_hash.sh

gen/git_url.hxx: | gen/
	cd gen && sh ../generators/git_url.sh

gen/sigmsgs.cxx: | gen/
	cd gen && sh ../generators/mksignal.sh sigmsgs.cxx

gen/initial.cxx: build/trashdump | gen/
	cd gen && sh ../generators/initial.sh ../src/initial.xs initial.cxx
