v6;
use Test;
use DBIish;

plan 17;

my %con-parms;

# If env var set, no parameter needed.
%con-parms<dbname> = 'dbdishtest' unless %*ENV<PGDATABASE>;
%con-parms<user> = 'postgres' unless %*ENV<PGUSER>;
%con-parms<port> = 5432; # Test for issue #62

my $dbh;

try {
  $dbh = DBIish.connect('Pg', |%con-parms);
  CATCH {
	    when X::DBIish::LibraryMissing | X::DBDish::ConnectionFailed {
		diag "$_\nCan't continue.";
	    }
            default { .throw; }
  }
}
without $dbh {
    skip-rest 'prerequisites failed';
    exit;
}

ok $dbh,    'Connected';

ok (my $sv = $dbh.server-version), "server-version ($sv)";

ok $dbh.pg-socket, "There's a socket";

is $dbh.quote('foo'),	    "'foo'",    'Quote literal';
is $dbh.quote('foo'):as-id, '"foo"',    'Quote Id';

lives-ok { $dbh.do('LISTEN test') }, 'Listen to test';
my $note = $dbh.pg-notifies;
isa-ok $note, Any, 'No notification';
lives-ok { $dbh.do('NOTIFY test') }, 'Notify test';
lives-ok { $dbh.do("NOTIFY test, 'Payload'") }, 'Notify test w/payload';
$note = $dbh.pg-notifies;
isa-ok $note, 'DBDish::Pg::Native::pg-notify', 'A notification received';
is $note.relname, 'test', 'Test channel';
isa-ok $note.be_pid, Int, 'Pid';
is $note.extra, '', 'No extras';
$note = $dbh.pg-notifies;
isa-ok $note, 'DBDish::Pg::Native::pg-notify', 'A notification received';
is $note.relname, 'test', 'Test channel';
isa-ok $note.be_pid, Int, 'Pid';
is $note.extra, 'Payload', 'w/ extras';

#dd $dbh.drv.data-sources(:user<postgres>);
#dd $dbh.table-info(:table<sal_emp>).allrows(:array-of-hash).list;
