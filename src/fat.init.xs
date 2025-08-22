fn cpu {|host frag vars|
	if {~ $frag} {
		ssh -t $host rcxs
	} else {
		{ var $vars; echo $frag } | ssh $host rcxs
	}
}

fn xsroot {|frag vars|
	if {~ $frag} {
		sudo rcxs
	} else {
		{ var $vars; echo $frag } | sudo rcxs
	}
}

result xs initial state built in `/bin/pwd on `/bin/date for <=$&version

