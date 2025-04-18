/* main.cxx -- initialization for xs */

#include "xs.hxx"
#include <stdio.h>
#include <locale.h>

extern int optind;
extern char *optarg;

extern char **environ;

int is_dump = 0;

/* checkfd -- open /dev/null on an fd if it is closed */
static void checkfd(int fd, OpenKind r) {
	int newFD;
	newFD = dup(fd);
	if (newFD != -1)
		close(newFD);
	else if (errno == EBADF && (newFD = eopen("/dev/null", r)) != -1)
		mvfd(newFD, fd);
}

/* initpath -- set $path based on the configuration default */
static void initpath(void) {
	int i;
	static const char * const path[] = { INITIAL_PATH };

	List* list = NULL;
	for (i = arraysize(path); i-- > 0;) {
		Term* t = mkstr((char *) path[i]);
		list = mklist(t, list);
	}
	vardef("path", NULL, list);
}

/* initpid -- set $pid for this shell */
static void initpid(void) {
	vardef("pid", NULL, mklist(mkstr(str("%d", getpid())), NULL));
}

/* runxsrc -- run the user's profile, if it exists */
static void runxsrc(int xsin) {
	const char *fmt = xsin ? "%L/.xsin" : "%L/.xsrc";
	char *xsrc = str(fmt, varlookup("home", NULL), "\001");
	int fd = eopen(xsrc, oOpen);
	if (fd != -1) {
		try {
			runfd(fd, xsrc, 0);
		} catch (List *e) {
			if (termeq(e->term, "exit"))
				exit(exitstatus(e->next));
			else if (termeq(e->term, "error"))
				eprint("%L\n",
				       e->next == NULL ? NULL : e->next->next,
				       " ");
			else if (!issilentsignal(e))
				eprint("uncaught exception: %L\n", e, " ");
			return;
		}
	}
}

/* usage -- print usage message and die */
static void usage(void) NORETURN;
static void usage(void) {
	eprint(
"usage: xs [-c command] [-silevxnpo?GZ] [file [args ...]]\n"
"	-h	show usage information; then exit\n"
"	-c cmd	execute argument\n"
"	-s	read commands from standard input; stop option parsing\n"
"	-i	interactive shell\n"
"	-l	login shell\n"
"	-e	exit if any command exits with false status\n"
"	-v	print input to standard error\n"
"	-x	print commands to standard error before executing\n"
"	-n	just parse; don't execute\n"
"	-p	don't load functions from the environment\n"
"	-o	don't open stdin, stdout, and stderr if they were closed\n"
"	-d	don't ignore SIGQUIT or SIGTERM\n"
"	-G	run without garbage collection\n"
"	-Z	don't load ~/.xsrc and ~/.xsin\n"
"	-V	show version/build information; then exit\n"
	);
	exit(1);
}

/* show_version -- print version/build info and exit */
static void show_version(void) {
	printf("%s\n%s\n", version, build);
	exit(1);
}

/* initgc -- initialize gc with just one marker */
static void initgc(void) {
	const char *name = "GC_MARKERS";
	char save[8];
	char *old = getenv(name);
	if (old) {
		strncpy(save, old, sizeof(save));
		save[sizeof(save)-1] = '\0';
	}
	setenv(name, "1", 1);
	GC_init();
	if (old) setenv(name, save, 1);
	else unsetenv(name);
}

/* shlevel -- set or update the SHLVL environment variable */
static void shlevel(void) {
	const char *name = "SHLVL";
	char *last = getenv(name);
	char next[8];
	if (last) snprintf(next, sizeof(next), "%d", atoi(last)+1);
	else strcpy(next, "1");
	setenv(name, next, 1);
}

static volatile bool loginshell = false;
bool islogin() {
	return loginshell;
}

/* main -- initialize, parse command arguments, and start running */
int main(int argc, char **argv) {
	initgc();
	int c;
	volatile int ac;
	char **volatile av;

	volatile int runflags = 0;		/* -[einvxL] */
	volatile bool isprotected = false;	/* -p */
	volatile bool norc = false;		/* -Z */
	volatile bool allowquit = false;	/* -d */
	volatile bool cmd_stdin = false;	/* -s */
	/* loginshell: see above */		/* -l or $0[0] == '-' */
	bool keepclosed = false;		/* -o */
	const char *volatile cmd = NULL;	/* -c */

	initconv();

	if (argc == 0) {
		argc = 1;
		argv = reinterpret_cast<char**>(ealloc(2 * sizeof (char *)));
		argv[0] = strdup("xs");
		argv[1] = NULL;
	}
	if (argv[0][0] == '-')
		loginshell = true;

	// Set optind to a known value to make the skip parsing not cause problems
	optind = 1;

	while ((c = getopt(argc, argv, "+eilxvnpodsc:hGZV")) != EOF)
		switch (c) {
#define FLAG(x, action) case x: action; break; 
		FLAG('c', cmd = optarg);
		FLAG('e', runflags |= eval_exitonfalse);
		FLAG('i', runflags |= run_interactive);
		FLAG('n', runflags |= run_noexec);
		FLAG('v', runflags |= run_echoinput);
		FLAG('x', runflags |= run_printcmds);
		FLAG('l', loginshell = true);
		FLAG('p', isprotected = true);
		FLAG('o', keepclosed = true);
		FLAG('d', allowquit = true);
		FLAG('s', cmd_stdin = true; goto getopt_done);
		FLAG('h', usage());
		FLAG('G', GC_disable());
		FLAG('Z', norc = true);
		FLAG('V', show_version());
		default:
			usage();
		}

getopt_done:
	if (cmd_stdin && cmd != NULL) {
		eprint("xs: -s and -c are incompatible\n");
		exit(1);
	}

	if (!keepclosed) {
		checkfd(0, oOpen);
		checkfd(1, oCreate);
		checkfd(2, oCreate);
	}

	if (
		cmd == NULL
	     && (optind == argc || cmd_stdin)
	     && (runflags & run_interactive) == 0
	     && isatty(0)
	)
		runflags |= run_interactive;

	ac = argc;
	av = argv;

	try {
		uselocale(newlocale(LC_ALL_MASK, "", (locale_t)0));
		initinput();
		initprims();

		shlevel();

		runinitial();

		initpath();
		initpid();
		initsignals(runflags & run_interactive, allowquit);
		hidevariables();
		initenv(environ, isprotected);

		if (!norc) {
			if (loginshell)
				runxsrc(0);

			if (runflags & run_interactive) {
				inithistory();
				runxsrc(1);
			}
		}

		if (cmd == NULL && !cmd_stdin && optind < ac) {
			int fd;
			char *file = av[optind++];
			if ((fd = eopen(file, oOpen)) == -1) {
				eprint("%s: %s\n", file, xsstrerror(errno));
				return 1;
			}
			vardef("*", NULL, listify(ac - optind, av + optind));
			vardef("0", NULL, mklist(mkstr(file), NULL));
			return exitstatus(runfd(fd, file, runflags));
		}

		vardef("*", NULL, listify(ac - optind, av + optind));
		vardef("0", NULL, mklist(mkstr(av[0]), NULL));
		if (cmd != NULL)
			return exitstatus(runstring(cmd, NULL, runflags));
		return exitstatus(runfd(0, "stdin", runflags));

	} catch (List *e) {
		if (termeq(e->term, "exit"))
			return exitstatus(e->next);
		else if (termeq(e->term, "error"))
			eprint("%L\n",
			       e->next == NULL ? NULL : e->next->next,
			       " ");
		else if (!issilentsignal(e))
			eprint("uncaught exception: %L\n", e, " ");
		return 1;
	}
}
