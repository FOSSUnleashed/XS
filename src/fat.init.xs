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

fn %in-path {|cmd|
	map {|f| if {access -x $f} {result $f} else result} $path^/^$cmd
}

fn us {|user frag vars|
	if {!~ $user} {
		user = -u $user
	} else if {~ $user -} {
		user = 
	}

	if {~ $frag} {
		sudo $user rcxs
	} else {
		{ var $vars; echo $frag } | sudo $user rcxs
	}
}

result xs initial state built in `/bin/pwd on `/bin/date for <=$&version
