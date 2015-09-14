#!/usr/bin/node

/**
 * PAM2 Client
 */

var pam2d_url = null,
    pam2d_command = [],
    pam2d_host = null,
    pam2d_port = 42763,
    pam2d_user = null,
    pam2d_password = null,
    args = process.argv,
    i = 0,
    len = args.length,
    is_command = false,
    matches,
    query,
    rsvp = require('./js/rsvp.js'),
    WebSocket = require('ws'),
    ws;

function show_help() {
	process.stdout.write([
		'',
		'PAM2 client, v 0.1',
		'',
		'USAGE:',
		'	pam2 [-u <username>] [-p <password>] [-h <hostname[:port]>] -q [...]',
		'',
		'All the arguments after the "-q" are considered part of query, and will be sent to server.',
		''
	].join('\n'));
}

function read_password() {

	var stdin = process.openStdin();
	
	process.stdout.write('Password: ' );  

	process.stdin.resume();

	process.stdin.setEncoding('utf8');
	process.stdin.setRawMode(true);  
	password = ''

	return new rsvp.Promise( function( accept, reject ) {
		
		procstdin = function (char) {

			char = char + "";

			switch (char) {
				case "\n": case "\r": case "\u0004":
					// They've finished typing their password
					process.stdin.setRawMode(false)
					stdin.pause();
					process.stdout.write('\n');
					process.stdin.removeListener('data', procstdin );
					accept(password);
					break
				case "\u0003":
					// Ctrl C
					console.log('^C');
					process.exit(1);
					break
				default:
					// More passsword characters
					password += char
					break
			}
		};

		process.stdin.on('data', procstdin );


	} );

}

if ( [ '--help', '/help' ].indexOf( args[2] ) > -1 ) {
	show_help();
	process.exit(0);
}

try {

	for ( i=2; i<len; i++ ) {

		if ( is_command === false ) {

			switch ( args[i] ) {
				case '-u':
					if ( pam2d_user === null ) {
						i++;
						pam2d_user = args[i] || null;
						if ( pam2d_user === null ) {
							throw new Error('Username expected!' );
						}
						break;
					}
				case '-p':
					if ( pam2d_password === null ) {
						i++;
						pam2d_password = args[i] || null;
						if ( pam2d_password === null ) {
							throw new Error('Password expected!');
						}
						break;
					}
				case '-h':
					if ( pam2d_host === null ) {
						i++;
						pam2d_host = args[i] || null;
						if ( pam2d_host === null ) {
							throw new Error('Hostname or HostName:port expected!');
						}
						break;
					}
				case '-q':
					is_command = true;
					break;

				default:
					throw new Error('Unrecognized argument: ' + args[i] );
					break;
			}

		} else {
		
			pam2d_command.push( args[i] );
		
		}
	}

	if ( pam2d_host === null ) {

		pam2d_host = 'localhost';

	} else {

		if ( matches = ( /^([a-zA-Z\-\_\.\d]+)(\:([\d]+))?$/.exec( pam2d_host ) ) ) {
			
			pam2d_host = matches[1];
			pam2d_port = ~~matches[3] || pam2d_port;

			if ( pam2d_port > 65535 || pam2d_port < 1 ) {
				throw new Error('Illegal port: ' + pam2d_port );
			}

		} else {
			throw new Error('Illegal host format. Use hostname or hostname:port notation (pam2d_host="' + pam2d_host + '")' );
		}
	}

	if ( pam2d_user === null ) {

		pam2d_user = process.env.USER || process.env.USERNAME;
		
		if ( pam2d_user === null ) {
			throw new Error(
				'Failed to determine the username for which context to run this command\n' +
				'Try using the -u argument'
			)
		}
	}

	if ( pam2d_command.length == 0 ) {
		throw('No query has been specified. Try using the -q arg1 arg2 ... argn.');
	}

} catch ( e ) {
	process.stderr.write(e + '\n\n' );
	process.exit(1);
}

for ( i=0, len = pam2d_command.length; i<len; i++ ) {
	pam2d_command[i] = '"'+pam2d_command[i].replace(/(["\s'$`\\])/g,'\\$1')+'"';
}

query = pam2d_command.join(' ');

// Enter async mode
( pam2d_password === null ? read_password() : rsvp.Promise.resolve( pam2d_password ) ).then( function( password ) {

	pam2d_password = password;

	if ( !pam2d_password ) {
		throw('Aborting. A password is required!');
	}

} ).then( function( dummy ) {

	// ok, we have everything setup. connect to websocket server

	ws = new WebSocket('ws://'+pam2d_host+':'+pam2d_port+'/', 'pam2' );

	return new rsvp.Promise( function( accept, reject ) {
		
		ws.on('open', function() {
			accept(true);
		});

		ws.on('error', function( err ) {
			reject(new Error(err) );
		} );

		setTimeout( function() {
			reject( new Error( "Failed to connect to server after 1 second" ) );
		}, 1000 );

	} );


} ).then(function( ok ) {

	return new rsvp.Promise( function( accept, reject ) {

		ws.on('message', function( message ) {
			accept( message );
		} );

		ws.send(JSON.stringify({
			"cmd": "query",
			"id": 1,
			"data": {
				"query": query,
				"user": pam2d_user,
				"password": pam2d_password
			}
		}));

		setTimeout( function() {
			reject( new Error("Server response timeouted"))
		}, 30000 );

	} );


} ).then( function( response ) {

	response = JSON.parse( response );

	var exit_code = display_response( response );

	ws.close();

	process.exit(exit_code);


} ).catch( function( error ) {

	try {

		ws.close();

	} catch(e){}

	process.stderr.write( error + '\n' );

	setTimeout( function() {

		process.exit(1);

	}, 500 );

});

function display_response( response ) {
	if ( !response ) {
		process.stderr.write('Server error' );
		return 1;
	}

	console.log( JSON.stringify( response, undefined, 4 ) );
	
	return !response || !response.ok ? 1 : 0;
}