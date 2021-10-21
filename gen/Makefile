

all: buildinfo.hxx git_date.hxx git_hash.hxx git_url.hxx sigmsgs.cxx initial.cxx

buildinfo.hxx: 
	sh ../generators/buildinfo.sh

git_date.hxx: 
	sh ../generators/git_date.sh

git_hash.hxx: 
	sh ../generators/git_hash.sh

git_url.hxx: 
	sh ../generators/git_url.sh

sigmsgs.cxx: 
	sh ../generators/mksignal.sh sigmsgs.cxx

initial.cxx:
	sh ../generators/initial.sh ../src/initial.xs initial.cxx
