#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;

my $dbh = FindmJob::Basic->dbh;

## remove old freelances which is older than one months
my $month_ago = time() - 40 * 86400;
my $rows = $dbh->do("DELETE FROM freelance WHERE inserted_at < $month_ago");
print "DELETE freelance: $rows\n";

$rows = $dbh->do("DELETE FROM object where tbl='freelance' and id not in (SELECT id FROM freelance)");
print "DELETE freelance object: $rows\n";

## jobs, for 3 months
$month_ago = time() - 100 * 86400;
$rows = $dbh->do("DELETE FROM job WHERE inserted_at < $month_ago");
print "DELETE job: $rows\n";

$rows = $dbh->do("DELETE FROM object where tbl='job' and id not in (SELECT id FROM job)");
print "DELETE job object: $rows\n";

# for both job and freelance
$rows = $dbh->do("DELETE FROM object_tag where object not in (SELECT id FROM object)");
print "DELETE object_tag: $rows\n";

# tags not used anymore
$rows = $dbh->do("DELETE FROM tag where id not in (SELECT DISTINCT tag FROM object_tag)");
print "DELETE tag: $rows\n";

# company does not have any jobs
$dbh->do("UPDATE company SET is_deletable=0 WHERE id IN (SELECT DISTINCT company_id FROM company_review)");
$rows = $dbh->do("DELETE FROM company WHERE is_deletable=1 AND id NOT IN (SELECT DISTINCT company_id FROM job)");
print "DELETE compnay: $rows\n";

print "Done\n";

1;