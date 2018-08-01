# publc_demo

This POC is based on MySQL which is an RDBMS with strong ACID implementation.
Notably its InnoDB storage engine supports transactions.

To run:
1. Install MySQL Server 8.0 with its client app Workbench
2. Use Workbench to connect to the server and run all .sql files in the project
3. Run node HomeTask.js

I started writing the logic in the Node client, and at some point decided to move all the logic to MySQL itself in a mechanism they have that's called Stored Procedures. This is in order to prevent a client-server ping-pong which is not really needed. I was going to put some SLEEP() commands in there to test concurrency from multiple clients, but I just found out my transcations don't commit when there's a SLEEP() inside the transaction. So, based on our testing needs, I can pull out logic from the SPs to the client.

To run a Stored Procedure (SP), run an SQL query called 

I created 4 SP's in the database:
SP_CREATE_DEMO - This overwrites everything in the database with some initial ledger items and some actions in the queue
SP_PROCESS_QUEUE - This is what the service is supposed to do. Runs endlessly processing items in the queue
SP_PROCESS_ACTION - This is called by SP_PROCESS_QUEUE after acquiring an actionId to process.
SP_CHECK_BALANCE_ERRORS - Shows a summary of the state of the system. Specifically look at err which shows a discrepancy in the total balance, if any (the sum of all the money in the system, including the bank, should always be 100,000,000,000)
