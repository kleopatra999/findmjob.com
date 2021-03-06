package FindmJob::WWW::Search;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Search;
use Data::Page;

sub search {
    my $c = shift;

    my $schema = $c->schema;

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $q = $c->param('q');
    my $loc = $c->param('loc') || '';
    my $by  = $c->param('by') || 'relevance';
    my $rest_url = $c->stash('rest') || '';
    my ($filename) = ($rest_url =~ m{([^/]+)\.html$});
    if ($filename) {
        $filename =~ s/\_by\_(date|relevance)$// and $by = $1;
        $filename =~ s/(^|\_)in\_(\w+)$// and $loc = $2;
        $q = $filename;
    }
    $c->stash('q'    => $q);
    $c->stash('loc'  => $loc);
    $c->stash('sort' => $by);

    my ($view_tab) = ($c->req->url->path =~ m{/\+(freelance|job)/});
    $view_tab ||= '';
    $c->stash(view_tab => $view_tab);

    my $search = FindmJob::Search->new;
    my $ret = $search->search_job( {
        'q'  => $q,
        loc  => $loc,
        sort => $by,
        rows => $rows,
        page => $p,
        tbl  => $view_tab,
    } );
    if ($ret->{total}) {
        my $schema = FindmJob::Basic->schema;

        # old sphinx
        # my @ids    = map { $_->{id} } @{$ret->{matches}};
        # my @jobids = map { $_->{id} } grep { $_->{tbl} eq 'job' } @{$ret->{matches}};
        # my @freelance_ids = map { $_->{id} } grep { $_->{tbl} eq 'freelance' } @{$ret->{matches}};

        # new es
        my @ids    = map { $_->{_source}->{id} } @{$ret->{hits}};
        my @jobids = map { $_->{_source}->{id} } grep { $_->{_type} eq 'job' } @{$ret->{hits}};
        my @freelance_ids = map { $_->{_source}->{id} } grep { $_->{_type} eq 'freelance' } @{$ret->{hits}};

        my %ids;
        if (@jobids) {
            my @jobs   = $schema->resultset('Job')->search( {
                id => { 'IN', \@jobids }
            } )->all;
            %ids = map { $_->id => $_ } @jobs;
        }
        if (@freelance_ids) {
            my @jobs   = $schema->resultset('Freelance')->search( {
                id => { 'IN', \@freelance_ids }
            } )->all;
            map { $ids{$_->id} = $_ } @jobs;
        }

        my @jobs = map { $ids{$_} } @ids;
        $c->stash(jobs => \@jobs);

        # pager
        my $pager = Data::Page->new();
        $pager->total_entries($ret->{total});
        $pager->entries_per_page($rows);
        $pager->current_page($p);
        $c->stash(pager => $pager);
    }

    $c->render(template => 'search');
}

1;