fn arrs {|*|
	.d 'List array variables'
	.a '[FILTER]'
	.c 'system'
	vars | grep -a \377^'[^[]\+\[' | tr -d \377 | sort -V \
		| grep \^^<={%argify $*}^.\* | column -c `{tput cols} \
		| less -iFX
}
fn astat {
	.d 'Display a status screen'
	.c 'system'
	%with-quit {
		watch -t -p -c -n1 \
			'xs -c ''d;load;thermal;vol;played playing'''
	}
}
fn battery {
	.d 'Show battery status'
	.c 'system'
	let (pspath = /sys/class/power_supply; full = 0; curr = 0; \
		ef; ec; en) {
		for d ($pspath/BAT?) {
			access -d $d && {
				ef = `{cat $d/energy_full_design}
				ec = `{cat $d/energy_full}
				en = `{cat $d/energy_now}
				full = `($full+$ec)
				curr = `($curr+$en)
				printf '%s %s (%.2f)'\n \
					`{basename $d} `{cat $d/status} \
					`(1.0*$ec/$ef)
			}
		}
		!~ $curr 0 && printf '%.1f%%'\n `(100.0*$curr/$full)
	}
}
fn bell {|*|
	.d 'Bell control'
	.a 'on|off'
	.c 'system'
	%only-X
	switch <={%argify $*} (
		off {pacmd unload-module module-x11-bell}
		on {pacmd load-module module-x11-bell sample=x11-bell \
			display=:0.0}
		{
			if {pacmd list-modules|grep -q module-x11-bell} {
				echo On
			} else {
				echo Off
			}
		}
	)
}
fn cookie {
	.d 'Fortune'
	.c 'system'
	let (subjects = art computers cookie definitions goedel \
			humorists literature people pets platitudes \
			politics science wisdom) {
		fortune -n 200 -s $subjects
	}
}
fn cs {|*|
	.d 'List compose sequences'
	.a '[-a]  # show all variations'
	.c 'system'
	.r 'u2o ulu'
	%with-read-lines <{grep -h '^<Multi_key>' ~/.XCompose \
				/usr/share/X11/locale/en_US.UTF-8/Compose | \
		grep -v -e '<dead' -e '<kana_' -e '<hebrew_' -e '<Arabic_' \
			-e '<Cyrillic_' -e '<Greek_' -e '<Ukrainian_' \
			-e '<KP_' -e '<ae>' -e '<AE>' -e '<ezh>' -e '<EZH>' \
			-e '<underbar>' -e '<.\?acute>' -e '<.\?tilde>' \
			-e '<.\?ring>' -e '<.\?diaeresis>' -e '<.\?grave>' \
			-e '<.\?cedilla>' -e '<.\?horn>' -e '<.\?circumflex>' \
			-e '<.\?breve>' -e '<.\?macron>' -e '<.\?acute>' \
			-e '<.\?caron>' -e '<.\?slash>' -e '<.\?oblique>' \
			-e '<U\([0-9A-Fa-f]\)\+>' \
		| grep -v -e '"   \b\(ascii[^ ]\+\|brace[^ ]\+\|at\|bar\|' \
			^'apostrophe\|numbersign\|bracket\(left\|right\)\) ' \
		| sed 's/^\(.\+ # \). . \(.\+\)$/\1\2/' \
		| if {~ $*(1) -a} cat else {uniq -f 4} \
	} {|*|
		kf = /usr/include/X11/keysymdef.h
		ksym = `{echo $*|sed 's|^[^:]\+:[[:space:]]\+"[^"]\+"' \
				^'[[:space:]]\+\([^ ]\+\).*$|\1|'}
		if {grep -q 'U[[:xdigit:]]\+\b' <{echo $ksym}} {
			echo $*
		} else {
			ksd = `{grep 'XK_'^$ksym^'\b' $kf}
			if {~ $#ksd 0} {
				echo $*
			} else {
				kuc = `{echo $ksd \
					|grep -o ' *U+[[:xdigit:]]\+ ' \
					|tr -d +|head -1}
				echo $*|sed 's|^\([^:]\+: \+"[^"]\+" \+\)' \
					^'[[:alpha:]]\+\(.*\)$|\1'^$kuc^'\2|'
			}
		}
	} | expand | awk -F: '{printf "%-48.48s:%s\n", ' \
				^'gensub(/^(.*) +$/, "\\1", "g", $1), ' \
				^'gensub(/ +/, " ", "g", $2)}' \
		| env LESSUTFBINFMT='*s?' less -iSFX
}
fn d {
	.d 'Date/time (local, UTC and TAI)'
	.c 'system'
	date
	date -u
	date +%t%s.%N
	let (a = `` '' {grep \^Leap /usr/share/zoneinfo/leapseconds|cut -f6}; \
		s = `{date +%s}; pf; nf; p; n; l; t) {
		pf = `{grep -e + <<<$a}
		nf = `{grep -e - <<<$a}
		p = $#pf
		n = $#nf
		l = `($p-$n)
		t = `($s+$l)
		printf %+d\t%u\n $l $t
	}
}
fn dt {|*|
	.d 'List top directory usage'
	.a '[-a] [DIR]'
	.c 'directory'
	let (eo = --exclude './.*') {
		if {~ $*(1) -a} {eo = ; * = $*(2 ...)}
		du $eo -t1 -h -d1 $*|grep -vE '^[.0-9KMGTPEZY]+'\t'\.$' \
			|sort -h -r -k1|head -15
	}
}
fn doc {|*|
	.d 'pushd to documentation directory of package'
	.a 'PACKAGE_NAME_GLOB'
	.a '-n PACKAGE_NAME'
	.c 'directory'
	if {~ $#* 0} {
		.usage doc
	} else if {~ $*(1) -n} {
		doc /$*(2)^\$
	} else if {!~ $* ()} {
		let (pl) {
			pl = `{find -L /usr/share/doc /usr/local/share/doc \
				-mindepth 1 -maxdepth 1 -type d \
				|grep -i '/usr.*/share/doc.*'^$*}
			if {~ $#pl 1} {
				pushd $pl
			} else if {~ $#pl ???*} {
				throw error doc 'more than 99 matches'
			} else {
				for p ($pl) {echo `{basename $p}}
				echo $#pl matches
			}
		}
	}
}
fn hd {
	.d 'Simple hex dump'
	.c 'system'
	hexdump -e '"%07.7_Ax  (%_Ad)\n"' \
		-e '"%07.7_ax  " 8/1 "%02x " "  " 8/1 "%02x " "\n"'
}
fn import-abook {|*|
	.d 'Import vcard to abook'
	.a 'VCARD_FILE'
	.c 'system'
	if {~ $#* 0} {
		.usage import-abook
	} else {
		access -- ~/.abook/addressbook \
			&& mv ~/.abook/addressbook ~/.abook/addressbook-OLD
		abook --convert --infile $* --informat vcard \
			--outformat abook --outfile ~/.abook/addressbook
		chmod 600 ~/.abook/addressbook
	}
}
fn la {|*|
	.c 'directory'
	.r 'll ls lt'
	ls -a $*
}
fn latest {
	.d 'List latest START processes for current user'
	.c 'process'
	%view-with-header 1 <{ps auk-start_time -U $USER} latest
}
fn list {|*|
	.d 'List file with syntax highlighting'
	.a '[-s SYNTAX|-f] FILE'
	.a '-l  # list SYNTAX names'
	.c 'file'
	if {~ $#* 0} {
		.usage list
	} else if {~ $* -l} {
		ls /usr/local/share/vis/lexers/*.lua | grep -v lexer\\\.lua \
			| xargs -I\{\} basename \{\} | sed s/\.lua\$// \
			| column -c `{tput cols} | less -iFX
	} else {
		let (syn; \
			lpath = /usr/local/share/vis/lexers; \
			fallback = false; \
			fn-canon = {|ext|
				%with-dict {|d|
					result <={%objget $d $ext $ext}
				} (1 man 3 man 5 man 7 man ascii text
					iso-8859 text c ansi_c sh bash
					dash bash posix bash bourne-again bash
					patch diff md markdown fs forth
					4th forth adb ada ads ada gpr ada
					rs rust rst rest p pascal py python
					js javascript es rc)} \
			) {
			if {~ $*(1) -s} {
				syn = $*(2)
				* = $*(3 ...)
			} else {
				if {~ $(1) -f} {
					fallback = true
					* = $*(2 ...)
				}
				{~ $#* 1 && access -- $*} || \
					{throw error list 'file?'}
				syn = `{echo $*|sed 's/^.*\.\([^.]\+\)$/\1/'}
				syn = <={canon $syn}
				{~ $syn () || !access -f $lpath/^$syn^.lua} && {
					syn = `{file -L $* | cut -d: -f2 \
						| awk '
/^ a .*\/env [^ ]+ script/ {print $3; next}
/^ a .*\/[^ ]+ (-[^ ]+ )?script/ {
	print gensub(/^ [^ ]+ .+\/([^ ]+) .*$/, "\\1", 1); next
}
// {print $1}
' \
						| tr '[[:upper:]]' '[[:lower:]]'}
					syn = <={canon $syn}
					access -f $lpath/^$syn^.lua || syn = ()
				}
				if {~ $syn ()} {
					if $fallback {syn = null} \
					else {throw error list \
						'specify -s SYNTAX or -f'}
				}
			}
			access -- $* || {throw error list 'file?'}
			if {file $*|grep -q 'CR line terminators'} {
				vis-highlight $syn <{cat $*|tr \r \n}
			} else {
				vis-highlight $syn $*
			} | nl >[2]/dev/null | less -iRFXS
		}
	}
}
fn ll {|*|
	.c 'directory'
	.r 'la ls lt'
	ls -lh $*
}
fn load {
	.d '1/5/15m loadavg; proc counts; last PID'
	.c 'process'
	cat /proc/loadavg
}
fn lock {|*|
	.d 'Lock screen'
	.a '-t  # transparent lock, disable DPMS; X only'
	.a '-a  # lock all consoles; vt only'
	.c 'system'
	.r 'screensaver'
	if {~ $DISPLAY ()} {
		vlock $*
	} else {
		~/.local/bin/lock $*
	}
}
fn lpman {|man|
	.d 'Print a man page'
	.a 'PAGE'
	.c 'file'
	if {~ $#man 0} {
		.usage lpman
	} else {
		env MANWIDTH=80 man $man | sed 's/^.*/    &/' \
			| lpr -o page-top=60 -o page-bottom=60 \
				-o page-left=60 -o lpi=8 -o cpi=12
	}
}
fn lpmd {|md|
	.d 'Print a markdown file'
	.a 'FILE'
	.c 'file'
	if {~ $#md 0} {
		.usage lpmd
	} else {
		markdown $md | w3m -T text/html -cols 80 | sed 's/^.*/    &/' \
			| lpr -o page-top=60 -o page-bottom=60 \
				-o page-left=60 -o lpi=8 -o cpi=12
	}
}
fn ls {|*|
	.c 'directory'
	.a '[ls_ARGS|-P]'
	.r 'la ll lt'
	if {~ $* -P} {
		* = `{echo $*|sed 's/-P//'}
		/usr/bin/ls --group-directories-first -v --color=yes $* \
			| less -RFXi
	} else {
		/usr/bin/ls --group-directories-first -v --color=auto $*
	}
}
fn lt {|*|
	.c 'directory'
	.r 'la ll ls'
	ls -lhtr $*
}
fn mamel {
	.d 'List installed MAME games'
	.c 'game'
	ls /usr/share/mame/roms|sed 's/\.zip$//'|column -c `{tput cols}
}
fn mdv {|*|
	.d 'Markdown file viewer'
	.a 'MARKDOWN_FILE'
	.c 'file'
	if {!~ $#* 1} {
		.usage mdv
	} else if {!access -f $*} {
		echo 'file?'
	} else {
		markdown -f fencedcode $* | w3m -X -T text/html -no-mouse \
			-no-proxy -o confirm_qq=0 -o document_root=`pwd
	}
}
fn name {|*|
	.d 'Set prompt text and terminal title.'
	.a '[NAME]'
	.c 'system'
	.r 'prompt title'
	if {~ $* ()} {
		prompt ''
		title `{echo $TERM|sed 's/-256color.*//'}
	} else {
		prompt $*
		title $*
	}
}
fn net {|*|
	.d 'Network status'
	.a '[-a]'
	.c 'system'
	let (flag) {
		if {!~ $* -a} {flag = --active}
		nmcli --fields name,type,device connection show $flag
	}
}
fn objs {|*|
	.d 'List object variables'
	.a '[FILTER]'
	.c 'system'
	let (tf = `mktemp) {
		vars | grep -a \377^objid: | tr -d \377 > $tf^02 # objs & names
		cat $tf^02 | grep -v '^objid:' | cut -d' ' -f3 > $tf^03 # keys
		grep -F -f $tf^03 $tf^02 > $tf^04 # objs and their names
		cat $tf^04 | sort -t: -k2 | split -d -n r/2 - $tf
			# 00: names; 01: objects
		cat $tf^01 | sed 's/^objid:[^ ]\+ = /{/' | sed 's/ \?obj$/}/' \
			> $tf^05 # objects rewritten as {key:value ...}
		paste $tf^00 $tf^05 | grep \^^<={%argify $*}^.\* \
			| column -c `{tput cols} | less -iFXS
		rm -f $tf^??
	}
}
fn oc {
	.d 'Onscreen clock'
	.c 'system'
	%with-quit {
		%without-cursor {
			watch -t -n 1 -p -c banner \\' '^\`date +%T\`\; \
							cal -n 3 --color=always
		}
	}
}
fn parse {|*|
	.d 'Parse an xs expression'
	.a '[EXPRESSION]'
	.c 'system'
	if {~ $#* 0} {
		let (c = <={~~ <={%parse 'xs: ' '  : '} \{*\}}) {
			if {!~ $c ()} {xs -nxc $c}}} \
	else {xs -nxc $^*}
}
fn pn {
	.d 'Users with active processes'
	.c 'process'
	ps haux|cut -d' ' -f1|sort|uniq
}
fn pp {|*|
	.d 'Prettyprint xs function'
	.a '[-c] NAME'
	.c 'system'
	if {~ $#* 0} {
		.usage pp
	} else if {~ $*(1) -c} {
		%with-tempfile f {
			pp $*(2) > $f
			if {grep -qx 'not a function' $f} {
				cat $f
			} else {
				list -s xs $f
			}
		}
	} else catch {|e|
		echo 'not a function'
	} {
		%pprint $*
	} | less -iRFXS
}
fn prs {|*|
	.d 'Display process info'
	.a '[-f] [prtstat_OPTIONS] NAME'
	.c 'process'
	if {~ $#* 0} {
		.usage prs
	} else {
		let (pgrep_option = -x) {
			{~ $*(1) -f} && {
				pgrep_option = $*(1)
				* = $*(2 ...)
			}
			let (pids = `{pgrep $pgrep_option $*}) {
				if {!~ $pids ()} {
					for pid $pids {
						!~ $#pids 1 && echo '========'
						prtstat $pid
					} | less -iFX
				} else {
					echo 'not found'
				}
			}
		}
	}
}
fn pt {|*|
	.d 'ps for user; only processes with terminal'
	.a '[[-fFcyM] USERNAME]'
	.c 'process'
	.r 'pu'
	%view-with-header 1 <{.pu $*|awk '{if ($14 != "?") print}'} pt
}
fn pu {|*|
	.d 'ps for user'
	.a '[[-fFCyM] USERNAME]'
	.c 'process'
	.r 'pt'
	%view-with-header 1 <{.pu $*} pu
}
fn screensaver {|*|
	.d 'Query/set display screensaver enable'
	.a '[on|off]'
	.a '(none)  # show current'
	.c 'system'
	.r 'lock'
	let (error = false) {
		if {~ $DISPLAY ()} {
			if {!~ `tty */tty*} {throw error screensaver 'not a tty'}
			if {~ $#* 0} {
				timeout = `{cat /sys/module/kernel/\
					^parameters/consoleblank}
				if {~ $timeout 0} {echo Off} \
				else {echo On}
			} else {
				switch $* (
				on {setterm -blank 15 -powerdown 15 >>/dev/tty}
				off {setterm -blank 0 -powerdown 0 >>/dev/tty}
				{error = true})
			}
		} else {
			if {~ $#* 0} {
				let (timeout) {
					timeout = `{xset q|grep timeout \
						|awk '{print $2}'}
					if {~ $timeout 0} {echo Off} \
					else {echo On}
				}
			} else {
				switch $* (
				on {xset +dpms; xset s on; xset s 900 0}
				off {xset -dpms; xset s off}
				{error = true})
			}
		}
		if $error {throw error screensaver 'on or off'}
	}
}
fn src {|*|
	.d 'pushd to K source directories'
	.a '[NAME]'
	.c 'directory'
	if {~ $#* 0} {
		find /usr/local/src -maxdepth 1 -mindepth 1 -type d \
			|xargs -I\{\} basename \{\}|column -c `{tput cols}
	} else {
		if {access -d /usr/local/src/$*} {
			pushd /usr/local/src/$*
		} else {echo 'not in /usr/local/src'}
	}
}
fn startwm {
	.d 'Start X window manager'
	.c 'system'
	if {!~ $DISPLAY ()} {
		throw error startwm 'already running'
	} else if {!~ `tty *tty*} {
		throw error startwm 'run from console'
	} else {
		cd; exec startx -- -logverbose 0 >~/.startx.log >[2=1]
	}
}
fn swapflush {
	.d 'Flush swapfile(s)'
	.c 'system'
	sudo swapoff -a && sudo swapon -a
}
fn thermal {
	.d 'Summarize system thermal status'
	.c 'system'
	sensors >[2]/dev/null | grep -e '^Physical' -e '^Package' \
				-e '^Core' -e '^fan' | sed 's/ *(.*$//'
}
fn title {|*|
	.d 'Set terminal title'
	.a '[TITLE]'
	.c 'system'
	.r 'prompt name'
	$&echo -n \e]0\;^$^*^\a
}
fn topc {
	.d 'List top %CPU processes'
	.c 'process'
	.r 'topm topr topt topv'
	ps auxk-%cpu|head -11
}
fn topm {
	.d 'List top %MEM processes'
	.c 'process'
	.r 'topc topr topt topv'
	ps auxk-%mem|head -11
}
fn topr {
	.d 'List top RSS processes'
	.c 'process'
	.r 'topc topm topt topv'
	ps auxk-rss|head -11
}
fn topt {
	.d 'List top TIME processes'
	.c 'process'
	.r 'topc topm topr topv'
	ps auxk-time|head -11
}
fn topv {
	.d 'List top VSZ processes'
	.c 'process'
	.r 'topc topm topr topt'
	ps auk-vsz|head -11
}
fn treec {|*|
	.d 'Display filesystem tree'
	.a 'DIRECTORY'
	.c 'directory'
	tree --du -hpugDFC $* | less -iRFX
}
fn tsmwd {
	.d 'Return to tsm working directory'
	.c 'directory'
	if {!~ $TSMWD ()} {cd $TSMWD; echo $TSMWD} else echo .
}
fn tss {|*|
	.d 'Terminal screen size utility'
	.a '-u  # update ROWS and COLUMNS environment vars'
	.a '-d  # delete ROWS and COLUMNS environment vars'
	.a '-q  # display ROWS and COLUMNS environment vars'
	.a '(none)  # show terminal size'
	.c 'system'
	switch $* (
	-d {COLUMNS = ; ROWS =}
	-u {(ROWS COLUMNS) = (`{tput lines} `{tput cols})}
	-q {var COLUMNS ROWS}
	{})
	~ $* () && {printf '%sx%s'\n `{tput cols} `{tput lines}}
}
fn u2o {|*|
	.d 'Unicode text to octal escapes'
	.a 'TEXT'
	.c 'system'
	.r 'cs ulu'
	if {~ $#* 0} {
		.usage u2o
	} else {
		echo -n $*|hexdump -b|grep -Eo '( [0-7]+)+'|tr ' ' \\\\
	}
}
fn uh {
	.d 'Undo history'
	.c 'system'
	!~ $history () && {
		let (li = `{cat $history|wc -l}) {
			history -d $li >/dev/null
			history -d `($li-1)
		}
	}
}
fn ulu {|*|
	.d 'Unicode lookup'
	.a 'PATTERN'
	.c 'system'
	.r 'cs u2o'
	if {~ $#* 0} {
		.usage ulu
	} else {let (ud = /usr/share/unicode/ucd/UnicodeData.txt) {
		%with-read-lines <{egrep -i -o '^[0-9a-f]{4,};[^;]*' \
						^$*^'[^;]*;' $ud} {|l|
			let ((hex desc) = <={~~ $l *\;*\;}; uni) {
				!~ $desc \<control\> && {
					hex = `{printf %8s $hex|tr ' ' 0}
					uni = <={%U $hex}
					printf %s\tU+%s\t%s\n $uni $hex $desc
				}
			}
		} | env LESSUTFBINFMT=*n!PRINT less -iFXS
	}}
}
fn vman {|*|
	.d 'View man page'
	.a '[man_OPTS] PAGE'
	.c 'file'
	%only-X
	if {~ $#* 0} {
		.usage vman
	} else {
		%with-tempfile f {
			{man -Tpdf $* >$f} && {zathura $f}
		}
	}
}
fn wallpaper {|*|
	.d 'Set wallpaper'
	.a '[-m MONITOR] FILE-OR-DIRECTORY'
	.a '[-m MONITOR] DELAY_MINUTES DIRECTORY'
	.a '(none)  # restore root window'
	.c 'system'
	%only-X
	local (pageopt = $pageopt) {
		let (geom; mon; monopt = '') {
			if {~ $*(1) -m} {
				mon = $*(2)
				monopt = $*(1 2); monopt = $^monopt
				* = $*(3 ...)
				geom = `{grep \^$mon <{xrandr}| \
					cut -d' ' -f3}
			}
			!~ $geom () && pageopt = -page $geom
			switch $#* (
			1 {	let (f) {
					access -f $* && f = $*
					access -d $* && wallpaper \
						`{find -L $* \
						\( -name '*.jpg' \
						-o -name '*.png' \) \
						|shuf|head -1}
					!~ $f () && {
						display -window root \
							$pageopt $f
					}
				}
			}
			2 {	let (m = $*(1); d = $*(2); \
					p = 'while true {wallpaper '; \
					f = 'while true \{wallpaper') {
					access -d $d && {
						pkill -f $f
						setsid xs -c \
						$p^$monopt^' ' \
						^$d^'; sleep ' \
						^`($m*60)^'}' &
					}
				}
			}
			{	pkill -f 'while true \{wallpaper'
				xsetroot -solid 'Slate Gray'
			})
		}
	}
}
fn where {
	.d 'Summarize user, host, tty, shell pid and working directory'
	.c 'system'
	printf '%s@%s[%s;%d]:%s'\n \
		$USER `{hostname -s} <={~~ `tty /dev/*} $pid `pwd
}
fn wisepony {
	.d 'Wise pony'
	.c 'system'
	cookie|ponysay|less -eRFX
}
fn wlpq {
	.d 'Watch lpq until empty'
	.c 'system'
	grep -c '^no entries' >/dev/null <{lpq} || {
		lpq; echo; lpq +20 >/dev/null
	}
	echo 'lpq is empty'
}
fn xcolors {|*|
	.d 'Display X11 colors with RGB values and names'
	.a '[xs_filter_thunk]  # on $r, $g, $b and $d'
	.c 'system'
	%with-read-lines <{showrgb} {|l|
		(r g b d) = `{echo $l}
		let (fn-render = {|f r g b d|
				printf `{.af $f}
				printf \e'[48;2;%d;%d;%dm %03d %03d %03d ' \
					^'%30s '^`.an^\n $r $g $b $r $g $b \
					<={%argify $d}}) {
			if {{~ $* ()} || {eval $*}} {
				render 0 $r $g $b $d
				render 7 $r $g $b $d
			}
		}
	} | less -iFXR
}
fn zathura {|*|
	.d 'Document viewer'
	.c 'file'
	setsid xembed -e /usr/bin/zathura $* >/dev/null >[2=1] &
}
