fn cpu {|host frag vars|
	if {~ $frag} {
		ssh -t $host rcxs
	} else {
		{ var $vars; echo $frag } | ssh $host rcxs
	}
}

fn x {echo From fat}

result xs initial state built in `/bin/pwd on `/bin/date for <=$&version

