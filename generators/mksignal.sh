#! /usr/bin/env sh

# generate xs's internal signal table from signal.h

if type cpp 2>/dev/null ; then
	:
else
	if type clang-cpp 2>/dev/null; then
		cpp() {
			clang-cpp $*
		}
	else
		echo >&2 Could not find cpp
		exit 1
	fi
fi

INCS=$(echo "#include <signal.h>" | cpp | grep include |
	sed 's/^[^"]*"//' | sed 's/".*$//' | sort | uniq)

exec >$1

cat <<EOP
#include "xs.hxx"
#include "sigmsgs.hxx"

const Sigmsgs signals[] = {
EOP

sed -n '
	s/^[ 	]*\#[ 	]*define[ 	]*_*SIG/SIG/
	s/\/\*[ 	]*//
	s/[ 	]*\*\///
	s/([@*+!]) //
	s/[ 	]*(.*)$//
	s/[ 	]*signal$//
	/^SIG[A-Z][A-Z0-9]*[ 	]/p

' $INCS | awk '
	BEGIN {
		nsig = 0

		# set mesg["SIGNAME"] to override a message.  since the
		# comments in /usr/include/sys/signal.h are awful, we
		# now provide messages for most signals

		mesg["SIGABRT"]		= "abort"
		mesg["SIGALRM"]		= "alarm clock"
		mesg["SIGBUS"]		= "bus error"
		mesg["SIGCHLD"]		= "child stopped or exited"
		mesg["SIGCLD"]		= "child stopped or exited"
		mesg["SIGCONT"]		= "continue"
		mesg["SIGEMT"]		= "EMT instruction"
		mesg["SIGFPE"]		= "floating point exception"
		mesg["SIGHUP"]		= "hangup"
		mesg["SIGILL"]		= "illegal instruction"
		mesg["SIGINFO"]		= "information request"
		mesg["SIGIO"]		= "input/output possible"
		mesg["SIGIOT"]		= "IOT instruction"
		mesg["SIGKILL"]		= "killed"
		mesg["SIGLOST"]		= "resource lost"
		mesg["SIGLWP"]		= "lightweight process library signal"
		mesg["SIGMIGRATE"]	= "migrate process"
		mesg["SIGPOLL"]		= "pollable event occurred"
		mesg["SIGPROF"]		= "profiling timer alarm"
		mesg["SIGPWR"]		= "power failure"
		mesg["SIGQUIT"]		= "quit"
		mesg["SIGRESERVE"]	= "reserved signal"
		mesg["SIGSEGV"]		= "segmentation violation"
		mesg["SIGSTOP"]		= "asynchronous stop"
		mesg["SIGSYS"]		= "bad argument to system call"
		mesg["SIGTERM"]		= "terminated"
		mesg["SIGTRAP"]		= "trace trap"
		mesg["SIGTSTP"]		= "stopped"
		mesg["SIGTTIN"]		= "background tty read"
		mesg["SIGTTOU"]		= "background tty write"
		mesg["SIGURG"]		= "urgent condition on i/o channel"
		mesg["SIGUSR1"]		= "user defined signal 1"
		mesg["SIGUSR2"]		= "user defined signal 2"
		mesg["SIGVTALRM"]	= "virtual timer alarm"
		mesg["SIGWAITING"]	= "all lightweight processes blocked"
		mesg["SIGWINCH"]	= "window size changed"
		mesg["SIGXCPU"]		= "exceeded CPU time limit"
		mesg["SIGXFSZ"]		= "exceeded file size limit"
		
		# these signals are dubious, but we may as well provide clean
		# messages for them. most of them occur on only one system,
		# or, more likely, are duplicates of one of the previous
		# messages.

		mesg["SIGAIO"]		= "base lan I/O available"
		mesg["SIGDANGER"]	= "danger - system page space full"
		mesg["SIGEMSG"]		= "process received an emergency message"
		mesg["SIGGRANT"]	= "HFT monitor mode granted"
		mesg["SIGIOINT"]	= "printer to backend error"
		mesg["SIGMSG"]		= "input data is in the HFT ring buffer"
		mesg["SIGPRE"]		= "programming exception"
		mesg["SIGPTY"]		= "pty I/O available"
		mesg["SIGRETRACT"]	= "HFT monitor mode should be relinguished"
		mesg["SIGSAK"]		= "secure attention key"
		mesg["SIGSOUND"]	= "HFT sound control has completed"
		mesg["SIGSTKFLT"]	= "stack fault"
		mesg["SIGUNUSED"]	= "unused signal"
		mesg["SIGVIRT"]		= "virtual time alarm"
		mesg["SIGWINDOW"]	= "window size changed"


		# set nomesg["SIGNAME"] to suppress message printing

		nomesg["SIGINT"] = 1
		nomesg["SIGPIPE"] = 1


		# set ignore["SIGNAME"] to explicitly ignore a named signal
		# (usually, this is just for things that look like signals
		# but really are not)

		ignore["SIGALL"]	= 1
		ignore["SIGARRAYSIZE"]	= 1
		ignore["SIGCATCHALL"]	= 1
		ignore["SIGDEFER"]	= 1
		ignore["SIGDIL"]	= 1
		ignore["SIGHOLD"]	= 1
		ignore["SIGIGNORE"]	= 1
		ignore["SIGMAX"]	= 1
		ignore["SIGPAUSE"]	= 1
		ignore["SIGRELSE"]	= 1
		ignore["SIGRTMAX"]	= 1
		ignore["SIGRTMIN"]	= 1
		ignore["SIGSETS"]	= 1
		ignore["SIGSTKSZ"]	= 1
		
		# upper to lowercase translation table: can someone give me an
		# easier way to do this that works in ancient versions of awk?
		
		for (i = 65; i <= 90; i++)	# 'A' to 'Z'
			uppertolower[sprintf("%c", i)] = sprintf("%c", i + 32)

	}
	sig[$1] == 0 && ignore[$1] == 0 {
		sig[$1] = ++nsig
		signame[nsig] = $1
		if (mesg[$1] == "" && nomesg[$1] == 0) {
			str = $3
			for (i = 4; i <= NF; i++)
				str = str " " $i
			mesg[$1] = str
		}
		# hack to print SIGIOT or SIGILL as "abort" if that is the
		# most common way of triggering it.
		if ($1 == "SIGABRT" && $2 ~ /^SIG/)
			mesg[$2] = mesg[$1]
	}
	END {
		for (i = 1; i <= nsig; i++) {
			signal = signame[i]
			# gawk, at very least, provides a tolower function,
			# but this should be portable. sigh.
			lcname = ""
			for (j = 1; j <= length(signal); j++) {
				c = substr(signal, j, 1)
				if (uppertolower[c] != "")
					c = uppertolower[c]
				lcname = lcname c
			}
			print "#ifdef", signal
			printf "\t{ %s,\t\"%s\",\t\"%s\" },\n", signal,
				lcname, mesg[signal]
			print "#endif"
		}
	}
'

cat <<EOP
};

const int nsignals = arraysize(signals);
EOP
