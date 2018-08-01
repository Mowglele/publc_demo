var mysql = require('mysql');

console.log("starting service and connecting to database");

var conn = mysql.createConnection({
	host: "localhost",
	user: "root",
	password: "",
	database: "publc_demo",
	multipleStatements: true
});

conn.connect(main);

function main(err) {
	if (err) throw err;
	
	process.on('SIGINT', function() {

		conn.query("CALL SP_CHECK_BALANCE_ERRORS()", function(err, results) {
			if (err) throw err;			
			console.log("--------------------------------");
			if (results.length < 1 || results[0].length < 1)
				console.log("No results from SP_CHECK_BALANCE_ERRORS... Weird!");
			else {
				console.log(results[0][0]);
			}
			console.log("--------------------------------");
			console.log("Arrivederchi!");
			conn.end();
		});
	});
	
	console.log("starting service main");
	
	conn.query("CALL SP_PROCESS_QUEUE()", function(err, results) {
		if (err) throw err;
		if (results[0][0].status == "done") {
			console.log("Nothing left to do - stalbet for 10 seconds");
			setTimeout(main, 10000);
		}
	});
}
