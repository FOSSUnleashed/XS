#! ./build/xs
PGM = $0
HERE = `pwd^/`{dirname $PGM}
XS = $HERE/../build/xs -p
VERBOSE = false
FORK = true
PLATFORM = `{uname -m}
if $VERBOSE { DOTARGS = -v }

let (TMPOUT = /dev/shm/xs.$pid.testout) {
    # Ends up without newlines
    fn output {
        cat $TMPOUT
    }
    fn run { |name code|
	let (dir = /dev/shm/xs.$pid) {
		rm -fr $dir
		mkdir $dir
		cd $dir
	}
        TESTNAME = $name
	log2 Running $name...
	if $FORK {
        	RETURNVALUE = <={fork {$code >$TMPOUT >[2=1]}}
	} else {
		RETURNVALUE = <={$code > $TMPOUT >[2=1]}
	}
	log2 Done running $name....
	log2 $TESTNAME produced output\:
	log2 `output
	log2 $TESTNAME exited\:
	log2 $RETURNVALUE
    }
}

let (passes = 0
     fails  = 0
	c_clear = \x1b[0m
	c_green = \x1b[32m
	c_red = \x1b[34m)
{
	if {~ $TERM dumb} {
		c_clear =
		c_green = 
		c_red = 
	}
    fn pass { 
	passes = `{expr 1 + $passes}
        log 'Passed: ' $TESTNAME
    }
    fn fail { 
	fails = `{expr 1 + $fails} 
	log 'Failed: ' $TESTNAME
    }
    fn results {
	log 'Expected passes:    ' $c_green $passes $c_clear
	log 'Unexpected failures:' $c_red $fails $c_clear
    	rm -r /dev/shm/xs.*
	exit $fails
    }
}
fn conds { |requirements| escape { |fn-return|
    for req $requirements {
    	if {! eval $req} {
            log $req failed
    	    fail
    	    return
    	}
    }
    pass
}}

fn expect-success { ||
    result $RETURNVALUE
}
fn expect-failure {
    ! expect-success
}
fn match-abs { |result|
    log2 Absolute matching...
    ~ `` '' output $^result
}
fn match { |result|
    log2 Matching...
    ~ `` '' output *^$^result^*
}
fn match-re { |result|
    log2 Match_re....
    eval '~ `` '''' output *'^$^result^'*'
}
let (logfile = `pwd^/tests/xs_tests.log)
{
    echo $HERE
    fn log { |msg|
        echo $msg | tee -a $logfile
    }
    fn log2 { |msg|
	if $VERBOSE { log $msg } else {echo $msg >> $logfile}
    }

    rm -f $logfile
    for file ($HERE/xs_tests/*.xs) {
	log2 File $file
	local (FILE = $file) . $DOTARGS $FILE
    }

    let (platform_tests = \
		`{ls $HERE/xs_tests/platform/$PLATFORM/*.xs >[2]/dev/null}) {
        if {!~ $platform_tests ()} {
            log '-------  Begin' $PLATFORM 'platform tests'
            for file ($platform_tests) {
                log2 Running $file
                local (FILE = $file) . $DOTARGS $FILE
            }
        } else log '-------  No' $PLATFORM 'platform tests'
    }
    cd $HERE
}
results
