package FindmJob::WWW::Root;

use Mojo::Base 'Mojolicious::Controller';
use Encode;
use List::Util 'shuffle';

sub index {
    my $c = shift;

    my $schema = $c->schema;
    my $dbh = $schema->storage->dbh;
    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 10,
        page => 1,
    });
    $c->stash->{jobs} = [$job_rs->all];
    my $freelance_rs = $schema->resultset('Freelance')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 10,
        page => 1,
    });
    $c->stash->{freelances} = [$freelance_rs->all];

    # popular locations
    $c->stash->{popular_locations} = [ $schema->resultset('Location')->search(undef, {
        order_by => 'job_num DESC',
        rows => 10, page => 1
    })->all ];

    my $sth = $dbh->prepare(<<SQL);
SELECT tag.* FROM tag JOIN stats_trends tr ON tr.tag_id=tag.id WHERE tr.dt > DATE_SUB(NOW(), INTERVAL 2 DAY) group by tr.tag_id order by tr.num desc;
SQL
    $sth->execute();
    $c->stash->{popular_tags} = $sth->fetchall_arrayref({});

    my $user_agent = $c->req->headers->user_agent;
    my $is_chrome = ($user_agent and $user_agent =~ /Chrome/) ? 1 : 0;
    $c->stash(is_chrome => $is_chrome);

    $c->render(template => 'index');
}

sub jobs {
    my $c = shift;

    my $schema = $c->schema;

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $is_feed = $c->stash('is_feed');
    if ( $is_feed ) {
        $rows = 20; # more for feeds
        $p = 1;
    }

    my $count = $schema->resultset('Job')->count();
    # avoid slow 'LIMIT 96828, 12'
    if ( $count > ($p - 1) * $rows ) {
        my $job_rs = $schema->resultset('Job')->search( undef, {
            order_by => 'inserted_at DESC',
            rows => $rows,
            page => $p
        });
        my @jobs = $job_rs->all;
        $c->stash->{pager} = $job_rs->pager;
        $c->stash->{jobs}  = \@jobs;

        if ($is_feed) {
            $c->stash(title => "Recent Jobs");
            map { $_->{tbl} = 'job' } @jobs;
            return $c->stash('feeds' => \@jobs);
        }
    }

    $c->render(template => 'jobs');
}

sub freelances {
    my $c = shift;

    my $schema = $c->schema;

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $is_feed = $c->stash('is_feed');
    if ($is_feed) {
        $rows = 20; # more for feeds
        $p = 1;
    }

    my $count = $schema->resultset('Freelance')->count();
    # avoid slow 'LIMIT 96828, 12'
    if ( $count > ($p - 1) * $rows ) {
        my $job_rs = $schema->resultset('Freelance')->search( undef, {
            order_by => 'inserted_at DESC',
            rows => $rows,
            page => $p
        });
        my @jobs = $job_rs->all;
        $c->stash->{pager} = $job_rs->pager;
        $c->stash->{jobs}  = \@jobs;

        if ($is_feed) {
            $c->stash(title => "Recent Freelances");
            map { $_->{tbl} = 'freelance' } @jobs;
            return $c->stash('feeds' => \@jobs);
        }
    }

    $c->render(template => 'freelances');
}

sub job {
    my $c = shift;

    my $schema = $c->schema;
    my $jobid = $c->stash('id');
    my $job_rs = $schema->resultset('Job');
    my $job = $job_rs->find($jobid);

    unless ($job) {
        $c->res->code(410); # Gone
        return $c->render(template => 'gone', object => 'job');
    }

    if ($job->source_url =~ 'jobs.github.com') {
        $job->title( decode_utf8($job->title) );
        $job->description( decode_utf8($job->description) );
    }
    $c->stash(job => $job);

    $c->stash(company_jobs => [ $job_rs->jobs_by_company($job->company_id, $job->id) ]);
    $c->stash(location_jobs => [ $job_rs->jobs_by_location($job->location_id, $job->id) ])
        if $job->location_id;
    foreach my $tag (shuffle @{ $job->tags }) {
        my @tag_jobs = $job_rs->jobs_by_tag($tag->{id}, $job->id);
        next unless @tag_jobs;
        $c->stash(tag_jobs_text => $tag->{text});
        $c->stash(tag_jobs => \@tag_jobs);
    }

    $c->render(template => 'job');
}

sub freelance {
    my $c = shift;

    my $schema = $c->schema;
    my $jobid = $c->stash('id');
    my $job = $schema->resultset('Freelance')->find($jobid);

    unless ($job) {
        $c->res->code(410); # Gone
        return $c->render(template => 'gone', object => 'freelance');
    }

    $c->stash(job => $job);

    $c->render(template => 'freelance');
}

sub location {
    my $c = shift;

    my $schema = $c->schema;
    my $location_id = $c->stash('id');

    my $location = $schema->resultset('Location')->find($location_id);

    unless ($location) {
        $c->res->code(410); # Gone
        return $c->render(template => 'gone', object => 'location');
    }

    $c->stash(location => $location);

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $is_feed = $c->stash('is_feed');
    if ($is_feed) {
        $rows = 20; # more for feeds
        $p = 1;
    }

    my $job_rs = $schema->resultset('Job')->search( {
        location_id => $location_id
    }, {
        order_by => 'inserted_at DESC',
        rows => $rows,
        page => $p
    });
    my @jobs = $job_rs->all;
    $c->stash(pager => $job_rs->pager);
    $c->stash(jobs  => [@jobs]);

    if ($is_feed) {
        $c->stash(title => "Jobs in " . $location->text);
        map { $_->{tbl} = 'job' } @jobs;
        return $c->stash('feeds' => \@jobs);
    }

    $c->render(template => 'location');
}

sub tag {
    my $c = shift;

    my $schema = $c->schema;
    my $tagid = $c->stash('id');

    my $tag;
    if (length($tagid) == 22) {
        $tag = $schema->resultset('Tag')->find($tagid);
    }
    unless ($tag) {
        $tag = $schema->resultset('Tag')->get_row_by_text($tagid);
        $tagid = $tag->id if $tag;
    }
    $c->stash(tag => $tag);

    unless ($tag) {
        $c->res->code(410); # Gone
        return $c->render(template => 'gone', object => 'tag');
    }

    my ($view_tab) = ($c->req->url->path =~ m{/\+(freelance|job)/});
    $view_tab ||= '';
    $c->stash(view_tab => $view_tab);

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;

    my $rs = $schema->resultset('ObjectTag')->search( {
        tag => $tagid,
        ($view_tab) ? (tbl => $view_tab) : (),
    }, {
        order_by => 'me.time DESC',
        prefetch => ['object'],
        '+select' => ['object.tbl', 'object.id'],
        '+as'     => ['tbl', 'object_id'],
        rows => 12,
        page => $p
    });

    my @obj;
    while (my $row = $rs->next) {
        my $tbl = $row->get_column('tbl');
        my $id  = $row->get_column('object_id');
        my $obj = $schema->resultset(ucfirst $tbl)->find($id);
        $obj->{tbl} = $tbl;
        push @obj, $obj;
    }

    if ($c->stash('is_feed')) {
        $c->stash(title => $tag->text);
        return $c->stash('feeds' => \@obj);
    } else {
        my $pager = $rs->pager;
        $c->stash(pager => $pager);
        $c->stash(objects => \@obj);

        # count number in tab
        my %count;
        if ($view_tab) {
            $count{$view_tab} = $pager->total_entries;
        }
        foreach my $tbl ('job', 'freelance') {
            next if $count{$tbl};
            $count{$tbl} = $schema->resultset('ObjectTag')->count( {
                tag => $tagid,
                'object.tbl' => $tbl,
            }, {
                prefetch => ['object']
            } );
        }
        $c->stash(count => \%count);
    }

    $c->render(template => 'tag');
}

1;