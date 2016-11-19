use Test::More;
use DBI;
use PGObject;
use PGObject::Type::ByteString;
PGObject::Type::ByteString->register();

plan skip_all => 'Not set up for dbtests'
     unless $ENV{DB_TESTING};

# DB Setup

my $predbh = DBI->connect('dbi:Pg:', 'postgres', undef,
   { PrintError => 0 });
plan skip_all => "Could not get superuser access to db. skipping"
     unless $predbh;

$predbh->do('CREATE DATABASE test_pgobject_type_bytestring');
my $dbh = DBI->connect('dbi:Pg:dbname=test_pgobject_type_bytestring');

# Planning

plan skipall => "No database connection, or connection failed"
     unless $dbh;

$dbh->do(qq|
CREATE or REPLACE FUNCTION test__roundtrip(in_col bytea) RETURNS bytea LANGUAGE SQL AS
\$\$
SELECT \$1;
\$\$;
|);

# Test cases

my $hexval = pack('C5', 0xCA, 0xFE, 0xBA, 0xBE, 0xd5);
my $obj = PGObject::Type::ByteString->new($hexval);
my ($ref) = PGObject->call_procedure(
   funcname   => 'roundtrip',
   funcprefix => 'test__',
   args       => [$obj],
   dbh        => $dbh,
);

my ($val) = values %$ref;
ok($val->isa('PGObject::Type::ByteString'), 'Roundtrip returns correct type');
is($val->{value}, $obj->{value}, 'Roundtrip returns same value');


# DB Cleanup

$dbh->disconnect;
$predbh->do('DROP DATABASE test_pgobject_type_datetime');

done_testing;
